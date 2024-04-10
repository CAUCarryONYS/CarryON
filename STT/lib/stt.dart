import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_speech/config/longrunning_result.dart';
import 'package:google_speech/generated/google/cloud/speech/v2/cloud_speech.pb.dart';
import 'package:google_speech/generated/google/longrunning/operations.pb.dart';
import 'package:google_speech/generated/google/longrunning/operations.pbgrpc.dart';
import 'package:google_speech/google_speech.dart';
import 'package:path_provider/path_provider.dart';

class AudioRecognize extends StatefulWidget {
  const AudioRecognize({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AudioRecognizeState();
}
class _AudioRecognizeState extends State<AudioRecognize> {
  bool recognizing = false;
  bool recognizeFinished = false;
  String text = '';
  String filename = 'test.wav';
  final myController = TextEditingController();
  void setFilename(String str) async{
    setState(() {
      filename=str;
    });
  }
  void recognize() async {
    setState(() {
      recognizing = true;
    });
    final serviceAccount = ServiceAccount.fromString(
        (await rootBundle.loadString('assets/test_service_account.json')));
    final speechToText = SpeechToTextV2.viaServiceAccount(serviceAccount,
        projectId: 'rosy-embassy-418409');
    final config = _getConfig();
    final audio = await _getAudioContent(filename);

    await speechToText.recognize(config, audio).then((value) {
      setState(() {
        text = value.results
            .map((e) => e.alternatives.first.transcript)
            .join('\n');
      });
    }).whenComplete(() => setState(() {
      recognizeFinished = true;
      recognizing = false;
    }));
  }

  RecognitionConfigV2 _getConfig() => RecognitionConfigV2(
    features: RecognitionFeatures(enableAutomaticPunctuation: true),
    autoDecodingConfig: AutoDetectDecodingConfig(),
    model: RecognitionModelV2.long,
    languageCodes: ['ko-KR'],
  );

  Future<void> _copyFileFromAssets(String name) async {
    var data = await rootBundle.load('assets/$name');
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path + '/$name';
    await File(path).writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }

  Future<List<int>> _getAudioContent(String name) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path + '/$name';
    if (!File(path).existsSync()) {
      await _copyFileFromAssets(name);
    }
    return File(path).readAsBytesSync().toList();
  }

  Future<Stream<List<int>>> _getAudioStream(String name) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path + '/$name';
    if (!File(path).existsSync()) {
      await _copyFileFromAssets(name);
    }

    final content = File(path).readAsBytesSync();

    // Set chunkLength to 25600 bytes
    const chunkLength = 25600;
    final stream = <List<int>>[];

    for (var start = 0; start < content.length; start += chunkLength) {
      final end = (start + chunkLength < content.length)
          ? start + chunkLength
          : content.length;
      stream.add(content.sublist(start, end));
    }

    return Stream.fromIterable(stream);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio File Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            if (recognizeFinished)
              _RecognizeContent(
                text: text,
              ),
            ElevatedButton(
              onPressed: recognizing ? () {} : recognize,
              child: recognizing
                  ? const CircularProgressIndicator()
                  : const Text('Test with recognize'),
            ),
            const SizedBox(
              height: 10.0,
            ),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class _RecognizeContent extends StatelessWidget {
  final String? text;

  const _RecognizeContent({Key? key, this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: <Widget>[
          const Text(
            'The text recognized by the Google Speech Api:',
          ),
          const SizedBox(
            height: 16.0,
          ),
          Text(
            text ?? '---',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
