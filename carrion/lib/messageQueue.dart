import 'dart:collection';

import 'focusedChatroomManager.dart';
import 'models/chatroomModel.dart';
import 'tts.dart';

class TTSMessage {
  String text;
  double? volume;
  double? pitch;
  double? rate;

  TTSMessage({required this.text, this.volume, this.pitch, this.rate});

  double get getVolume => volume ?? 1;
  double get getPitch => pitch ?? 1;
  double get getRate => rate ?? 0.5;
}

class Messagequeue {
  late FocusedChatroomManager _focusedChatroomManager;
  late TTS _tts;
  late int nowChatroomId;

  late List<Queue<TTSMessage>> messageQueue;
  late Queue<TTSMessage> alertMessageQueue;
  late List<Chatroom> chatroomQueue;
  bool isPlaying = false;

  Messagequeue(FocusedChatroomManager fm, TTS t) {
    _tts = t;
    _focusedChatroomManager = fm;
    messageQueue = List.empty(growable: true);
    chatroomQueue = List.empty(growable: true);

    for (var i = 0; i < _focusedChatroomManager.nowFocus.length; i++) {
      messageQueue.add(Queue());
      chatroomQueue.add(_focusedChatroomManager.nowFocus.elementAt(i));
    }
    alertMessageQueue = Queue();
  }

  void addMessage(String message, int chatroomId) {
    for (int i = 0; i < chatroomQueue.length; i++) {
      if (chatroomQueue.elementAt(i).chatRoomId == chatroomId) {
        messageQueue.elementAt(i).add(TTSMessage(text: message));
        if (i != _focusedChatroomManager.index) cutOffMessageQueue(i);
        break;
      }
    }
    play();
  }

  Future<void> cutOffMessageQueue(int index) async {
    var len = _getQueueLength(messageQueue[index]);
    while (len > 130) {
      messageQueue[index].removeFirst();
      len = _getQueueLength(messageQueue[index]);
    }
  }

  void addAlertMessage(String message) {
    alertMessageQueue.clear();
    alertMessageQueue.add(TTSMessage(text: message));
    play();
  }

  void play() async {
    if (isPlaying) return;
    isPlaying = true;
    while (alertMessageQueue.isNotEmpty) {
      var message = alertMessageQueue.removeFirst();
      message.pitch = 0.8;
      await speak(message);
    }

    while (messageQueue[_focusedChatroomManager.index].isNotEmpty) {
      while (alertMessageQueue.isNotEmpty) {
        var message = alertMessageQueue.removeFirst();
        message.pitch = 0.8;
        await speak(message);
      }
      var rate = _calcSpeechRate(messageQueue[_focusedChatroomManager.index]);

      var message = messageQueue[_focusedChatroomManager.index].removeFirst();
      message.rate = rate;
      await speak(message);
    }

    isPlaying = false;
  }

  Future<void> delay() async {
    return Future<void>.delayed(const Duration(milliseconds: 300), () {});
  }

  double _calcSpeechRate(Queue<TTSMessage> textQueue) {
    int textLen = _getQueueLength(textQueue);
    double p = 1;
    if (textLen > 130) {
      p = 1.8;
    } else if (textLen > 100) {
      p = 1.6;
    } else if (textLen > 60) {
      p = 1.4;
    } else if (textLen > 30) {
      p = 1.2;
    } else {
      p = 1;
    }
    return p / 2;
  }

  int _getQueueLength(Queue<TTSMessage> textQueue) {
    int len = 0;
    for (var element in textQueue) {
      len += element.text.length;
    }
    return len;
  }

  Future<void> speak(TTSMessage message) async {
    _tts.newVoiceText = message.text;
    await _tts.flutterTts.setVolume(message.getVolume);
    await _tts.flutterTts.setPitch(message.getPitch);
    await _tts.setSpeed(message.getRate);
    await _tts.speak();
  }
}
