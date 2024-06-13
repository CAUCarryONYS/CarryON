import 'dart:async';

import '../screens/homePage.dart';
import '../screens/loginPage.dart';
import 'package:flutter/foundation.dart';

import '../tts.dart';
import '/loginManager.dart';
import 'package:flutter/material.dart';

import '../server/server_connect.dart';

class LoadingPage extends StatefulWidget {
  LoadingPage({super.key, required this.tts});
  TTS tts;

  ServerConnect serverConnect = ServerConnect();

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  bool? isAutoLogin;
  late LoginManager loginManager;

  @override
  void initState() {
    super.initState();
    checkAutoLogin().then((_) => pushNextPage());
  }

  void pushNextPage() {
    if (!(isAutoLogin ?? false)) {
      if (kDebugMode) {
        print("AutoLogin failed.");
      }
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => LoginPage(tts: widget.tts)));
    } else {
      if (kDebugMode) {
        print("AutoLogin success");
      }
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => HomePage(
                  serverConnect: widget.serverConnect, chatTTS: widget.tts)));
    }
  }

  Future<void> checkAutoLogin() async {
    loginManager = LoginManager(serverConnect: widget.serverConnect);
    await loginManager.loadFile();
    if (loginManager.isAutoLogin == null) {
      isAutoLogin = false;
      return;
    }
    if (loginManager.isAutoLogin == false) {
      isAutoLogin = false;
      return;
    } else {
      isAutoLogin = await loginManager.login();
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        //backgroundColor: const Color(0xffECF1F6),
        body: SingleChildScrollView(
            child: SafeArea(
                child: Center(
                    child: Column(children: [
      const SizedBox(
        height: 50,
      ),
      const Text(
        "CarriOn",
        style: TextStyle(
            fontSize: 62,
            fontWeight: FontWeight.bold,
            color: Color(0xff26408B)),
      ),
      /*const SizedBox(
                  height: 10,
                ),*/
      const Text(
        '보다 안전한 메세지',
        style: TextStyle(
            color: Color(0xff0E0536),
            fontSize: 18,
            fontWeight: FontWeight.w600),
      ),
      const SizedBox(
        height: 80,
      ),
    ])))));
  }
}
