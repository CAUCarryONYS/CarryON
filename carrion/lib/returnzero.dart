import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Returnzero {
  static const _authorizationEndpoint =
      'https://openapi.vito.ai/v1/authenticate';
  static const _transcribeEndpoint = 'https://openapi.vito.ai/v1/transcribe';
  static const _streamingEndpoint =
      'wss://openapi.vito.ai/v1/transcribe:streaming';

  static const _id = 'G9CqueHggSW0fDZl3eO0';
  static const _password = 'gT69a4KIlLLepjxf1Zkw9ynZLVymGgU_xwXGWsmf';

  IOWebSocketChannel? streamingSocket;

  bool _isAuthorized = false;
  bool _isRecognizing = false;
  bool _stop = false;
  String _filename = "";
  String lastText = "";

  late String _token;

  void setFileName(String filename) {
    _filename = filename;
  }

  final Map<String, String> _requestTokenHeader = {
    'accept': 'application/json',
    'Content-Type': 'application/x-www-form-urlencoded'
  };

  String get _requestTokenBody => json.encode({
        'client_id': 'G9CqueHggSW0fDZl3eO0',
        'client_secret': 'gT69a4KIlLLepjxf1Zkw9ynZLVymGgU_xwXGWsmf'
      });
  Map<String, String> get _transcribePostHeader => {
        'accept': 'application/json',
        'Authorization': 'Bearer $_token',
        'Content-Type': 'multipart/form-data',
      };
  Map<String, String> get _transcribeGetHeader => {
        'accept': 'application/json',
        'Authorization': 'Bearer $_token',
      };
  Map<String, String> get _streamingHeader => {
        'Authorization': 'Bearer $_token',
      };

  Stream<String> streamingRecognize(Stream<List<int>> audioStream) async* {
    String queryParams =
        '/?sample_rate=16000&encoding=LINEAR16&keyword=뉴진스:3.5';
    lastText = "";
    if (_isRecognizing) {
      if (kDebugMode) {
        print("already recognizing");
      }
      return;
    }
    

    streamingSocket = IOWebSocketChannel.connect(
        _streamingEndpoint + queryParams,
        headers: _streamingHeader);
    _isRecognizing = true;
    streamingSocket!.sink.addStream(audioStream);

    await for (String st in streamingSocket!.stream) {
      var text = getText(st);
      if (isFinal(st)) {
        lastText = text;
        yield lastText;
      }
      if (kDebugMode) {
        print(text);
      }
    }
    if (kDebugMode) {
      print("streaming end.");
    }
    
    _isRecognizing = false;
  }
  Future<void> endStreaming()async{
    await streamingSocket!.sink.close();
  }

  Future<bool> requestToken() async {
    if (_isAuthorized) return true;
    late http.Response response;
    try {
      response = await http.post(
        Uri.parse(_authorizationEndpoint),
        headers: _requestTokenHeader,
        body: 'client_id=$_id&client_secret=$_password',
      );
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      return false;
    }

    if (response.statusCode != 200) {
      if (kDebugMode) {
        print(json.decode(response.body)['msg']);
      }
      return false;
    }
    _token = json.decode(response.body)['access_token'];
    _isAuthorized = true;
    return true;
  }

  Future<String> recognize() async {
    String text = "";
    final sw = Stopwatch();
    if (kDebugMode) sw.start();

    var path = _filename;
    if (!File(path).existsSync()) {
      await copyFileFromAssets(_filename);
    }
    File audioFile = File(path);

    List<int> audioBytes = audioFile.readAsBytesSync();
    String base64Audio = base64Encode(audioBytes);
    if (kDebugMode) {
      print(base64Audio);
    }
    var request = http.MultipartRequest(
      'POST',
      Uri.parse(_transcribeEndpoint),
    );
    final httpAudio = await http.MultipartFile.fromPath('file', path);

    request.files.add(httpAudio);
    request.fields['config'] = json.encode({});
    request.headers.addAll(_transcribePostHeader);

    var transcribeResponseStream = await request.send();
    var transcribeResponse =
        await http.Response.fromStream(transcribeResponseStream);
    if (transcribeResponse.statusCode != 200) {
      if (kDebugMode) {
        print(
            "Cannot upload transcribe. Status:${transcribeResponse.statusCode}");
        print(transcribeResponse.body.toString());
      }
      return "";
    }
    String transcribeID = json.decode(transcribeResponse.body)['id'];

    var response = await _getTranscribeResponse(transcribeID);
    String status = json.decode(response.body)["status"];
    var retryNum = 0;
    while (status == 'transcribing') {
      if (retryNum > 3) {
        throw "cannot get the transcribed text";
      }
      retryNum++;

      sleep(const Duration(seconds: 3));
      if (kDebugMode) {
        print("retry...");
      }
      response = await _getTranscribeResponse(transcribeID);
      status = json.decode(response.body)["status"];
    }
    if (status == 'fail') {
      throw "transcribing fail";
    }
    if (kDebugMode) {
      sw.stop();
      print("ReturnZero recognization time: ${sw.elapsedMicroseconds}microsec");
    }
    text = json.decode(response.body)['results']['utterances'][0]['msg'];
    return text;
  }

  Future<dynamic> _getTranscribeResponse(String transcribeID) async {
    http.Response response = await http.get(
        Uri.parse("$_transcribeEndpoint/$transcribeID"),
        headers: _transcribeGetHeader);

    if (response.statusCode != 200) {
      if (kDebugMode) {
        print("Cannot get transcribe. Status:${response.statusCode}");
        print(json.decode(response.body)['msg']);
      }
      throw json.decode(response.body)['msg'];
    }

    return response;
  }

  static Future<void> copyFileFromAssets(String name) async {
    var data = await rootBundle.load('assets/$name');
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$name';
    await File(path).writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }

  static String getText(dynamic res) {
    return json.decode(res)['alternatives'][0]['text'];
  }

  static bool isFinal(dynamic res) {
    return json.decode(res)['final'];
  }
}
