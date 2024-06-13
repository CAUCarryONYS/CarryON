import 'package:audio_service/audio_service.dart';
import 'package:carrion/audioHandler.dart';
import 'package:flutter/material.dart';
import 'screens/homePage.dart';
import 'screens/loadingPage.dart';
import 'screens/loginPage.dart';
import 'package:flutter_foreground_service/flutter_foreground_service.dart';

import 'tts.dart';

late AudioHandler _audioHandler;
late AudioButtonHandler buttonHandler;

void main() async{
  _audioHandler = await AudioService.init(
    builder: () => buttonHandler = AudioButtonHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.ryanheise.myapp.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  TTS chatTTS = TTS();
  @override
  initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: LoadingPage(tts: chatTTS),
    );
  }
}
