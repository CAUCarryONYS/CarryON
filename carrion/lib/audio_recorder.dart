import 'dart:async';
import 'dart:convert';
import 'package:carrion/main.dart';

import 'alertAudioManager.dart';
import 'audioHandler.dart';
import 'messageQueue.dart';

import './focusedChatroomManager.dart';

import './returnzero.dart';
import './proper_noun_fixer.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:audioplayers/audioplayers.dart';

//import './stt.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

import 'models/chatroomModel.dart';
import 'platform/audio_recorder_platform.dart';
import 'server/server_connect.dart';
import 'stt.dart';
import 'tts.dart';
import 'ui.dart';

class Recorder extends StatefulWidget {
  final Chatroom chatroom;
  final ServerConnect serverConnect;
  final TTS chatTts;

  final void Function(String str, int recieverChatroomId) onStop;
  final FocusedChatroomManager focusedChatroomManager;

  const Recorder({
    super.key,
    required this.onStop,
    required this.focusedChatroomManager,
    required this.chatroom,
    required this.serverConnect,
    required this.chatTts,
  });

  @override
  State<Recorder> createState() => _RecorderState();
}

class _RecorderState extends State<Recorder> with AudioRecorderMixin {
  Returnzero rtzr = Returnzero();
  ProperNounFixer pnFixer = ProperNounFixer();
  Alertaudiomanager alertaudiomanager = Alertaudiomanager();

  late Messagequeue mq;

  TTS get chatTts => widget.chatTts;
  int get myId => widget.serverConnect.primaryKey;

  late AudioPlayer player = AudioPlayer();

  bool isRecording = false;

  int get originChatroomId => widget.focusedChatroomManager.now.chatRoomId;
  late int chatroomId;

  late final String myUrl;
  WebSocketChannel? _channel;
  bool ignoreNext = false;

  STT stt = STT();
  String oldText = "", newText = "";
  int _recordDuration = 0;

  Timer? _timer;
  int nonChatDuration = 0;
  bool get isReadyForRecieveOthersMessage => nonChatDuration > 10;

  late final AudioRecorder _audioRecorder;
  StreamSubscription<RecordState>? _recordSub;
  RecordState _recordState = RecordState.stop;
  StreamSubscription<Amplitude>? _amplitudeSub;
  Amplitude? _amplitude;
  Stream<Uint8List>? audioStream = null;

  String nowChatRoom = "";

  late AudioButtonHandler audioHandler;

  @override
  void initState() {
    chatroomId = originChatroomId;
    getNowChatRoom();
    myUrl = "ws://copytixe.iptime.org:8085/ws/$myId";
    _connectToWebSocket();
    pnFixer.loadFile();
    _audioRecorder = AudioRecorder();
    rtzr.requestToken();
    _recordSub = _audioRecorder.onStateChanged().listen((recordState) {
      _updateRecordState(recordState);
    });

    _amplitudeSub = _audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 300))
        .listen((amp) {
      setState(() => _amplitude = amp);
    });
    mq = Messagequeue(widget.focusedChatroomManager, widget.chatTts);
    startTimer();

    // Create the audio player.
    player = AudioPlayer();

    // Set the release mode to keep the source after playback has completed.
    player.setReleaseMode(ReleaseMode.stop);

    buttonHandler.setButtonFunc(controllRecording, nextChatRoom);

    super.initState();
  }

  @override
  dispose() {
    endTimer();
    _recordSub?.cancel();
    _amplitudeSub?.cancel();
    _audioRecorder.dispose();
    _channel!.sink.close();
    // Release all sources and dispose the player.
    player.dispose();
    buttonHandler.init();
    super.dispose();
  }

  void startTimer() {
    if (isRecording) return;
    endTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      nonChatDuration++;
      setState(() {});
    });
  }

  void endTimer() {
    if (_timer != null) _timer!.cancel();
    nonChatDuration = 0;
  }

  void _connectToWebSocket() async {
    _channel = WebSocketChannel.connect(Uri.parse(myUrl));
    _channel!.stream.listen(
      (message) {
        print('recieve chan Received message: $message');
        _handleReceivedMessage(message);
      },
      onError: (error) {
        print('WebSocket stream error: $error');
      },
      onDone: () {
        print('WebSocket stream closed');
      },
    );
  }

  void _handleReceivedMessage(String message) async {
    final decodedMessage = json.decode(message);
    final messageContent = decodedMessage['message'];
    final senderContent = decodedMessage['senderId'];
    final int messageChatroomId = decodedMessage['chatRoomId'];
    final chatroomName = decodedMessage['chatRoomName'];
    final participants = List<String>.from(decodedMessage['participantNames']);

    startTimer();
    // if (chatroomId == messageChatroomId) {
    //   // 이 채팅방이면
    //   if (senderContent == myId) {
    //   } else {
    //     chatTts.setText(messageContent);
    //   }
    // } else {
    //   if (senderContent != myId) {
    //     chatroomId = messageChatroomId;
    //     String text;
    //     if (participants.length == 2) {
    //       text = getChatroomName(participants);
    //     } else {
    //       text = chatroomName;
    //     }
    //     nowChatRoom = text;
    //     alertChatRoomChanged();
    //     chatTts.setText(messageContent);
    //   }
    // }
    if (senderContent != myId) {
      mq.addMessage(messageContent, messageChatroomId);
      if (messageChatroomId != chatroomId) {
        var num = widget.focusedChatroomManager.getNumOfNext(messageChatroomId);
        if (num > 0) alertaudiomanager.messageAlert(num);
      }
    }
  }

  String getChatroomName(List<String> input) {
    String name = "";
    for (var element in input) {
      if (element != widget.serverConnect.myName) {
        name += "$element, ";
      }
    }
    name = name.substring(0, name.length - 2);
    return name;
  }

  void _sendMessage(String message) {
    if (ignoreNext) {
      ignoreNext = false;
      return;
    }

    final messageData = {
      'senderId': widget.serverConnect.primaryKey,
      'chatRoomId': chatroomId,
      'message': message,
    };
    _channel?.sink.add(json.encode(messageData));
  }

  Future<void> _start() async {
    try {
      oldText = "";
      if (await _audioRecorder.hasPermission()) {
        const encoder = AudioEncoder.pcm16bits;

        if (!await _isEncoderSupported(encoder)) {
          return;
        }

        final devs = await _audioRecorder.listInputDevices();
        debugPrint(devs.toString());

        const config =
            RecordConfig(encoder: encoder, numChannels: 1, sampleRate: 16000);

        // Record to file
        //await recordFile(_audioRecorder, config);

        // Record to stream

        audioStream = await _audioRecorder.startStream(config);
        var textStream = rtzr.streamingRecognize(audioStream!);
        
        
        textStream.listen(
          (event) {
            print(event);
            setState(() {
              oldText = event;
              newText = pnFixer.fix(oldText);
              _sendMessage(newText);
            });
          },
        );
        _recordDuration = 0;
        isRecording = true;
        endTimer();
        startRecordTimer();
        alertaudiomanager.recordStart();
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<void> _stop() async {
    final path = await _audioRecorder.stop();
    await rtzr.endStreaming();
    print("Stop");

    //stt.setFilename(path.toString());
    //text = await stt.recognize();
    //rtzr.setFileName(path.toString());
    //text = await rtzr.recognize();
    print(oldText);
    isRecording = false;
    startTimer();
    alertaudiomanager.recordStop();
    if (mounted) setState(() {});
    /* 파일 업로드 */
    //widget.onStop(text);
  }

  Future<void> _pause() => _audioRecorder.pause();

  Future<void> _resume() => _audioRecorder.resume();

  void _updateRecordState(RecordState recordState) {
    setState(() => _recordState = recordState);

    switch (recordState) {
      case RecordState.pause:
        _timer?.cancel();
        break;
      case RecordState.record:
        startTimer();
        break;
      case RecordState.stop:
        _timer?.cancel();
        _recordDuration = 0;
        break;
    }
  }

  Future<bool> _isEncoderSupported(AudioEncoder encoder) async {
    final isSupported = await _audioRecorder.isEncoderSupported(
      encoder,
    );

    if (!isSupported) {
      debugPrint('${encoder.name} is not supported on this platform.');
      debugPrint('Supported encoders are:');

      for (final e in AudioEncoder.values) {
        if (await _audioRecorder.isEncoderSupported(e)) {
          debugPrint('- ${encoder.name}');
        }
      }
    }

    return isSupported;
  }

  Future<void> nextChatRoom() async {
    widget.focusedChatroomManager.getNext();

    getNowChatRoom();
    alertChatRoomChanged();
    setState(() {});
  }

  void alertChatRoomChanged() async {
    if (isRecording) ignoreNext = true;
    mq.addAlertMessage("$nowChatRoom 채팅방");
  }

  void getNowChatRoom() {
    String output = "";
    output =
        widget.focusedChatroomManager.now.getNames(widget.serverConnect.myName);
    nowChatRoom = output;
    chatroomId = widget.focusedChatroomManager.now.chatRoomId;
  }

  @override
  Widget build(BuildContext context) {
    return 
        Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _buildRecordStopControl(),
                    const SizedBox(width: 20),
                    // _buildPauseResumeControl(),
                    const SizedBox(
                      width: 20,
                      height: 50,
                    ),
                    _buildText(),
                    Text(newText),
                    ElevatedButton(
                        onPressed: () {
                          nextChatRoom();
                        },
                        child: Text(nowChatRoom)),
                  ],
                ),
              ],
            ),
            /*if (_amplitude != null) ...[
              const SizedBox(height: 40),
              Text('Current: ${_amplitude?.current ?? 0.0}'),
              Text('Max: ${_amplitude?.max ?? 0.0}'),
            ],*/
          ],
        ),
      );
  }

  Widget _buildRecordStopControl() {
    late Icon icon;
    late Color color;
    late double spreadRadius;

    if (_recordState != RecordState.stop) {
      icon = Icon(Icons.mic_none_outlined,
          color: Colors.yellow.shade400, size: 70);
      color = const Color(0xff26408B);
      spreadRadius = 10;
    } else {
      final theme = Theme.of(context);
      icon = const Icon(Icons.mic_none_outlined,
          color: Color(0xffD9E2EC), size: 70);
      color = const Color(0xff26408B);
      spreadRadius = 1;
    }

    return AnimatedContainer(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff6688B0),
            spreadRadius: spreadRadius,
            blurRadius: 16,
            offset: const Offset(0, 0), // changes position of shadow
          ),
        ],
      ),
      duration: const Duration(microseconds: 200),
      child: InkWell(
        child: SizedBox(width: 200, height: 200, child: icon),
        onTap: () {
          (_recordState != RecordState.stop) ? _stop() : _start();
        },
      ),
    );
  }
  Future<void> controllRecording() async{
    (_recordState != RecordState.stop) ? _stop() : _start();
  }

  Widget _buildPauseResumeControl() {
    if (_recordState == RecordState.stop) {
      return const SizedBox.shrink();
    }

    late Icon icon;
    late Color color;

    if (_recordState == RecordState.record) {
      icon = const Icon(Icons.pause, color: Colors.red, size: 30);
      color = Colors.red.withOpacity(0.1);
    } else {
      final theme = Theme.of(context);
      icon = const Icon(Icons.play_arrow, color: Colors.red, size: 30);
      color = theme.primaryColor.withOpacity(0.1);
    }

    return ClipOval(
      child: Material(
        color: color,
        child: InkWell(
          child: SizedBox(width: 56, height: 56, child: icon),
          onTap: () {
            (_recordState == RecordState.pause) ? _resume() : _pause();
          },
        ),
      ),
    );
  }

  Widget _buildText() {
    if (_recordState != RecordState.stop) {
      return _buildTimer();
    }

    return const Text("");
  }

  Widget _buildTimer() {
    final String minutes = _formatNumber(_recordDuration ~/ 60);
    final String seconds = _formatNumber(_recordDuration % 60);

    return Text(
      'recording\n  $minutes : $seconds',
      style: const TextStyle(color: Colors.red),
    );
  }

  String _formatNumber(int number) {
    String numberStr = number.toString();
    if (number < 10) {
      numberStr = '0$numberStr';
    }

    return numberStr;
  }

  void startRecordTimer() {
    _recordDuration = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _recordDuration++;
      setState(() {});
    });
  }
}
