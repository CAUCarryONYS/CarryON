import 'dart:collection';

import 'package:audioplayers/audioplayers.dart';

class Alertaudiomanager {
  static const String recordingStartAudioFilename = "recordStart.mp3";
  static const String recordingStopAudioFilename = "recordStop.mp3";
  static const List<String> messageAlertAudioFileName = [
    "newChat.mp3",
    "newChat2.mp3",
    "newChat3.mp3"
  ];

  bool isPlay = false;

  Queue<String> filenameQueue = Queue();

  AudioPlayer player = AudioPlayer();

  void recordStart() {
    filenameQueue.add(recordingStartAudioFilename);
    play();
  }

  void recordStop() {
    filenameQueue.add(recordingStopAudioFilename);
    play();
  }

  void messageAlert([int? num]) {
    var index = num == null ? 0 : num - 1;
    filenameQueue.add(messageAlertAudioFileName[index]);
    play();
  }

  void play() async {
    if (isPlay) {
      return;
    }
    isPlay = true;
    while (filenameQueue.isNotEmpty) {
      await player.setSource(AssetSource(filenameQueue.first));
      player.resume();
      filenameQueue.removeFirst();
      await delay();
    }
    isPlay = false;
  }

  Future<void> delay() async {
    return Future<void>.delayed(const Duration(milliseconds: 1200), () {});
  }
}
