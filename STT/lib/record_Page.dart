import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import './audio_player.dart';
import './audio_recorder.dart';

//void main() => runApp(const MyApp());

class recordPage extends StatefulWidget {
  const recordPage({super.key});

  @override
  State<recordPage> createState() => _MyAppState();
}

class _MyAppState extends State<recordPage> {
  bool showPlayer = false;
  String? audioPath;

  @override
  void initState() {
    showPlayer = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            children: [
              Flexible(
                flex: 1,
                child: Recorder(
                  onStop: (path) {
                    if (kDebugMode) print('Recorded file path: $path');
                    setState(() {
                      audioPath = path;
                      showPlayer = true;
                    });
                  },
                ),
              ),

              /*const Flexible(
                flex: 1,
                child: recordStt(),
              ),*/
            ],
          ),
        ),
      ),
    );
  }
}
