import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:sensors/sensors.dart';
import './focusedChatroomManager.dart';
import './audio_recorder.dart';
import '../server/server_connect.dart';
import 'package:flutter/material.dart';
import 'package:chat_bubbles/chat_bubbles.dart';
import 'models/chatroomModel.dart';
import 'tts.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:just_audio/just_audio.dart';

import 'package:intl/intl.dart';

bool isDriving = false;

class UI extends StatelessWidget {
  const UI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      //home: const ChatUI(title: ''),
    );
  }
}

class ChatUI extends StatefulWidget {
  final String title;
  final int myId;
  final ServerConnect serverConnect;
  final Chatroom chatroom;
  final int chatroomId;
  final int recipientId;
  final TTS chatTts;
  FocusedChatroomManager focusedChatroomManager;

  ChatUI({
    super.key,
    required this.title,
    required this.myId,
    required this.serverConnect,
    required this.chatroom,
    required this.chatroomId,
    required this.recipientId,
    required this.chatTts,
    required this.focusedChatroomManager,
  });

  @override
  State<ChatUI> createState() => _ChatUIState();
}

class _ChatUIState extends State<ChatUI> {
  final SpeedDetector _speedDetector = SpeedDetector();
  List<Message> messageList = <Message>[];
  late final String myUrl;
  WebSocketChannel? _channel;
  bool isCarMode = false;
  int unrecievedTime = 0;
  bool get isReadyForRecieveOthersMessage => unrecievedTime > 10;

  late TTS chatTts;

  final scrollController = ScrollController();
  final textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.focusedChatroomManager.enter(widget.chatroom);
    chatTts = widget.chatTts;
    myUrl = "ws://copytixe.iptime.org:8085/ws/${widget.myId}";
    _initWebSocket();
    _speedDetector.startDetection(_onSpeedChanged);
  }

  void _onSpeedChanged(bool isDrivingMode) {
    setState(() {});
  }

  Future<void> getMessage() async {
    messageList = await widget.serverConnect.getMessageList(widget.chatroomId, chatTts);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _speedDetector.stopDetection();
    _channel!.sink.close();
    super.dispose();
  }

  void _initWebSocket() async {
    await getMessage();
    _connectToWebSocket();
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

  void _handleReceivedMessage(String message) {
    final decodedMessage = json.decode(message);
    final messageContent = decodedMessage['message'];
    final senderId = decodedMessage['senderId'];
    final senderName = decodedMessage['senderName'];
    final timestamp = decodedMessage['timestamp'];
    final profileImage = decodedMessage['profileImage'];

    setState(() {
      messageList.add(Message(
        chatTts: chatTts,
        message: messageContent,
        senderId: senderId,
        senderName: senderName,
        timestamp: timestamp,
        profileImage: profileImage,
      ));
    });
  }

  void _sendMessage(String message, [int? recieverChatroomId]) {
    bool addMsg = (recieverChatroomId == null);
    recieverChatroomId ??= widget.chatroomId;
    final messageData = {
      'senderId': widget.serverConnect.primaryKey,
      'chatRoomId': recieverChatroomId,
      'message': message,
    };
    _channel?.sink.add(json.encode(messageData));
    if (addMsg) {
      var msg = Message(
          chatTts: chatTts,
          message: message,
          senderId: widget.serverConnect.primaryKey,
          senderName: widget.serverConnect.myName,
          timestamp: DateTime.now().toIso8601String(),
          profileImage: ''
      );
      messageList.add(msg);
    }
  }

  void _switchToDrivingMode() async {
    isDriving = true;
    _channel!.sink.close();
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => Recorder(
              onStop: (String message, int id) {
                _sendMessage(message, id);
              },
              focusedChatroomManager: widget.focusedChatroomManager,
              chatroom: widget.chatroom,
              chatTts: chatTts,
              serverConnect: widget.serverConnect,
            )
        )
    );

    isDriving = false;
    setState(() {
      _initWebSocket();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!isCarMode) return getNormarModeView();
    return getNormarModeView();
  }

  Widget getNormarModeView() {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.5), // 상단 부분 반투명하게
        title: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(widget.chatroom.getNames(widget.serverConnect.myName)),
              ],
            ),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: () {
              _switchToDrivingMode();
            },
            child: const Text("운전 모드", style: TextStyle(color: Colors.indigoAccent)),
          ),
        ]),
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: ListView.separated(
              reverse: true,
              shrinkWrap: true,
              controller: scrollController,
              padding: const EdgeInsets.only(bottom: 80.0), // 하단 패딩 추가
              itemBuilder: (BuildContext context, int index) {
                return messageList[messageList.length - index - 1].getWidget(widget.myId);
              },
              separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 5),
              itemCount: messageList.length,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.white.withOpacity(0.0), // 아래 부분 반투명하게
              padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
              child: Card(
                color: Colors.white, // 입력 텍스트필드 흰색
                child: TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    hintText: "Message...",
                    hintStyle: TextStyle(color: Colors.black54),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(15.0),
                  ),
                  onSubmitted: (text) {
                    setState(() {
                      scrollController.animateTo(0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut);
                    });
                    _sendMessage(text);
                    textController.clear();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Message {
  TTS chatTts;
  String message;
  int senderId;
  String senderName;
  String timestamp;
  String profileImage;
  bool isTTS;
  DateTime dt = DateTime.now();

  Message({
    required this.chatTts,
    required this.message,
    required this.senderId,
    required this.senderName,
    required this.timestamp,
    required this.profileImage,
    this.isTTS = true,
  });
  String getTimeString() {
    String ret = "";
    if (timestamp != null) {
      var last = DateTime.parse(timestamp!);
      var now = DateTime.now();

      last = last.add(const Duration(hours: 9));

      ret = DateFormat.jm('en_US').format(last);
    }
    return ret;
  }

  CircleAvatar getAvatar(){
    ImageProvider<Object>? ip;

    if(profileImage.isEmpty){
      ip = AssetImage('assets/image.png');
    }else{
      ip = MemoryImage(base64Decode(profileImage));
    }
    return CircleAvatar(
      backgroundImage: ip,
      maxRadius: 20,
    );
  }


  Widget getWidget(int userId) {
    final isSender = userId == senderId;
    final bubbleColor = isSender ? Colors.indigoAccent.shade200 : Colors.indigo.shade50;
    final textColor = isSender ? Colors.white : Colors.black;
    final borderRadius = isSender
        ? BorderRadius.only(
      topLeft: Radius.circular(40),
      topRight: Radius.circular(30),
      bottomLeft: Radius.circular(40),
    )
        : BorderRadius.only(
      topLeft: Radius.circular(0),
      topRight: Radius.circular(40),
      bottomLeft: Radius.circular(30),
      bottomRight: Radius.circular(40),
    );

    return Column(
      crossAxisAlignment: isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (!isSender)
          Align(
            heightFactor: 0.5,
          child: Row(
            children: [
              getAvatar(),
              SizedBox(width: 10),
              Text(senderName, style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          ),
        Row(
          mainAxisAlignment: isSender?MainAxisAlignment.end:MainAxisAlignment.start,
          children: [
            SizedBox(width: 30,),
            Container(
              constraints: BoxConstraints(minWidth: 50, maxWidth: 300),
              margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: borderRadius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),],
              ),
            ),
          ]
        ),
        SizedBox(height: 2),
        Row(
          mainAxisAlignment: isSender?MainAxisAlignment.end:MainAxisAlignment.start,
          children: [
        SizedBox(width: 45,),
            Text(
          getTimeString(),
          style: TextStyle(
            fontSize: 12,
            color: Colors.black45,
          ),
        ),
        SizedBox(width: 10,),
          ],
        )
        
      ],
    );
  }
  
  /*
  static CircleAvatar getAvatar(Uint8List? data, double maxRadius) {
    ImageProvider<Object> image;
    if (data == null) {
      image = defaultImage;
    } else {
      image = MemoryImage(data!);
    }
    return CircleAvatar(
      backgroundImage: image,
      maxRadius: maxRadius,
    );
  }
  */
}

class SpeedDetector {
  static const int SPEED_THRESHOLD = 2; // 20 km/h
  static const int UPDATE_INTERVAL = 1000; // 1초

  double _speed = 0.0;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  Timer? _timer;

  void startDetection(Function(bool) callback) {
    Geolocator.getPositionStream().listen((position) {
      _speed = position.speed; // This is your speed
      callback(_speed >= SPEED_THRESHOLD);
    });
  }

  void stopDetection() {
    //_accelerometerSubscription?.cancel();
    // _timer?.cancel();
  }

  double getSpeed() {
    return _speed;
  }
}
