import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io' show File, Platform;
import 'dart:math';

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';

enum TtsState { playing, stopped, paused, continued }

class TextQueueManager {
  Queue<String> alertQueue = Queue();
  Queue<String> textQueue = Queue();
  Queue<Queue<String>> otherQueue = Queue();
  Queue<int> chatroomIdQueue = Queue();

  String? getNextText() {
    String? str;
    if (alertQueue.isNotEmpty) {
      str = alertQueue.removeFirst();
    } else if (textQueue.isEmpty) {}
    return str;
  }
}

class TTS {
  static const String filename = "tts_setting.json";
  File? file;
  late FlutterTts flutterTts;
  String? language;
  String? engine;
  double volume = 1;
  double pitch = 1.0;
  double rate = 0.5;
  double maxSpeed = 1.0;
  bool isCurrentLanguageInstalled = false;

  String? newVoiceText;
  int? _inputLength;
  bool isSpeaking = false;

  Queue<String> alertQueue = Queue();
  Queue<String> textQueue = Queue();
  Queue<String> otherQueue = Queue();

  TtsState ttsState = TtsState.stopped;

  bool get isPlaying => ttsState == TtsState.playing;
  bool get isStopped => ttsState == TtsState.stopped;
  bool get isPaused => ttsState == TtsState.paused;
  bool get isContinued => ttsState == TtsState.continued;

  bool get isIOS => !kIsWeb && Platform.isIOS;
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isWindows => !kIsWeb && Platform.isWindows;
  bool get isWeb => kIsWeb;

  Future<File> getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    const path = '/$filename';
    return File(directory.path + path);
  }

  void saveFile() async {
    final ttsSetting = {
      'engine': engine,
      'language': language,
    };
    var jsonString = json.encode(ttsSetting);
    file = await getFile();
    file!.writeAsString(jsonString);
    print("save at ${file!.path}");
  }

  void loadFile() async {
    String jsonString;
    try {
      file = await getFile();
      jsonString = await file!.readAsString();
      var ttsSetting = json.decode(jsonString);
      language = ttsSetting['language'];
      engine = ttsSetting['engine'];
      if (language == null || engine == null) return;
      await flutterTts.setEngine(engine!);
      await flutterTts.setLanguage(language!);
      if (isAndroid) {
        flutterTts
            .isLanguageInstalled(language!)
            .then((value) => isCurrentLanguageInstalled = (value as bool));
      }
    } catch (e) {
      print(e.toString());
      return;
    }
  }

  TTS() {
    initTts();
  }

  dynamic initTts() {
    flutterTts = FlutterTts();

    _setAwaitOptions();

    if (isAndroid) {
      _getDefaultEngine();
      _getDefaultVoice();
    }

    flutterTts.setStartHandler(() {
      print("Playing");
      ttsState = TtsState.playing;
    });

    flutterTts.setCompletionHandler(() {
      print("Complete");
      ttsState = TtsState.stopped;
    });

    flutterTts.setCancelHandler(() {
      print("Cancel");
      ttsState = TtsState.stopped;
    });

    flutterTts.setPauseHandler(() {
      print("Paused");
      ttsState = TtsState.paused;
    });

    flutterTts.setContinueHandler(() {
      print("Continued");
      ttsState = TtsState.continued;
    });

    flutterTts.setErrorHandler((msg) {
      print("error: $msg");
      ttsState = TtsState.stopped;
    });
    loadFile();
  }

  int _getQueueLength() {
    int len = 0;
    for (var element in textQueue) {
      len += element.length;
    }
    return len;
  }

  double _calcSpeechRate(int nowTextLen) {
    int textLen = _getQueueLength() + nowTextLen;
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
    if (p > maxSpeed / rate) p = maxSpeed / rate;
    return p;
  }

  void setMaxSpeed(double input) async {
    if (input > 1.0) {
      maxSpeed = 1.0;
    } else if (input < 0.6) {
      maxSpeed = 0.6;
    } else {
      maxSpeed = input;
    }
    newVoiceText = "이 속도로 말합니다";
    await flutterTts.setVolume(volume);
    await flutterTts.setPitch(pitch);
    await flutterTts.setSpeechRate(maxSpeed);
    speak();
  }

  Future<void> setSpeed(double input) async {
    if (input > maxSpeed) input = maxSpeed;
    await flutterTts.setSpeechRate(input);
  }

  void upMaxSpeed() {
    setMaxSpeed(maxSpeed + 0.05);
  }

  void downMaxSpeed() {
    setMaxSpeed(maxSpeed - 0.05);
  }

  Future<dynamic> getLanguages() async => await flutterTts.getLanguages;

  Future<dynamic> getEngines() async => await flutterTts.getEngines;

  Future<void> _getDefaultEngine() async {
    engine = await flutterTts.getDefaultEngine;
  }

  Future<void> _getDefaultVoice() async {
    var voice = await flutterTts.getDefaultVoice;
  }

  Future<void> speak() async {
    var lang = language ?? "";
    print("Speak language: $lang");

    if (newVoiceText != null) {
      if (newVoiceText!.isNotEmpty) {
        await flutterTts.speak(newVoiceText!);
      }
    }
  }

  Future<void> justSpeak() async {}

  Future<void> _setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> stop() async {
    var result = await flutterTts.stop();
    textQueue.clear();
    if (result == 1) ttsState = TtsState.stopped;
  }

  Future<void> pause() async {
    var result = await flutterTts.pause();
    if (result == 1) ttsState = TtsState.paused;
  }

  List<DropdownMenuItem<String>> getEnginesDropDownMenuItems(
      List<dynamic> engines) {
    var items = <DropdownMenuItem<String>>[];
    for (dynamic type in engines) {
      items.add(DropdownMenuItem(
          value: type as String?, child: Text((type as String))));
    }
    return items;
  }

  void changedEnginesDropDownItem(String? selectedEngine) async {
    await flutterTts.setEngine(selectedEngine!);
    language = null;
    engine = selectedEngine;
  }

  List<DropdownMenuItem<String>> getLanguageDropDownMenuItems(
      List<dynamic> languages) {
    var items = <DropdownMenuItem<String>>[];
    for (dynamic type in languages) {
      items.add(DropdownMenuItem(
          value: type as String?, child: Text((type as String))));
    }
    return items;
  }

  void changedLanguageDropDownItem(String? selectedType) {
    language = selectedType;
    flutterTts.setLanguage(language!);
    if (isAndroid) {
      flutterTts
          .isLanguageInstalled(language!)
          .then((value) => isCurrentLanguageInstalled = (value as bool));
    }
  }

  void setText(String text, [double? speed]) async {
    textQueue.add(text);

    if (!isSpeaking) {
      isSpeaking = true;
      while (textQueue.isNotEmpty) {
        newVoiceText = textQueue.removeFirst();
        await flutterTts.setVolume(volume);
        if (speed == null) {
          await flutterTts
              .setSpeechRate(rate * _calcSpeechRate(newVoiceText!.length));
        }
        await flutterTts.setPitch(pitch);
        await speak();
      }
      isSpeaking = false;
    }
  }

  Widget engineSection() {
    if (isAndroid) {
      return FutureBuilder<dynamic>(
          future: getEngines(),
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.hasData) {
              return enginesDropDownSection(snapshot.data as List<dynamic>);
            } else if (snapshot.hasError) {
              return Text('Error loading engines...');
            } else
              return Text('Loading engines...');
          });
    } else
      return Container(width: 0, height: 0);
  }

  Widget futureBuilder() => FutureBuilder<dynamic>(
      future: getLanguages(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.hasData) {
          return languageDropDownSection(snapshot.data as List<dynamic>);
        } else if (snapshot.hasError) {
          return Text('Error loading languages...');
        } else
          return Text('Loading Languages...');
      });

  Widget enginesDropDownSection(List<dynamic> engines) => Container(
        padding: EdgeInsets.only(top: 50.0),
        child: DropdownButton(
          value: engine,
          items: getEnginesDropDownMenuItems(engines),
          onChanged: changedEnginesDropDownItem,
        ),
      );

  Widget languageDropDownSection(List<dynamic> languages) => Container(
      padding: EdgeInsets.only(top: 10.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
        DropdownButton(
          value: language,
          items: getLanguageDropDownMenuItems(languages),
          onChanged: changedLanguageDropDownItem,
        ),
        Visibility(
          visible: isAndroid,
          child: Text("Is installed: $isCurrentLanguageInstalled"),
        ),
      ]));
}
