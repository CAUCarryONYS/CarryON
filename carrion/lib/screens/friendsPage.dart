import 'dart:async';

import '../focusedChatroomManager.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../screens/chatStateInterface.dart';
import '../server/server_connect.dart';
import '../tts.dart';
import '../widgets/errorDialog.dart';
import 'package:flutter/foundation.dart';

import '../widgets/friendList.dart';
import 'package:flutter/material.dart';
import '../models/chatUserModel.dart';

class friendPage extends StatefulWidget {
  friendPage(
      {super.key,
        required this.serverConnect,
        required this.chatTTS,
        required this.focusedChatroomManager});
  ServerConnect serverConnect;
  TTS chatTTS;
  FocusedChatroomManager focusedChatroomManager;

  @override
  State<friendPage> createState() => _friendPageState();
}

class _friendPageState extends State<friendPage> with ChatState {
  List<ChatUsers> friendList = List.empty(growable: true);

  @override
  void initState() {
    serverConnect = widget.serverConnect;
    super.initState();
    getFriendList();
  }

  @override
  Function get getList => getFriendList;

  void getFriendList() async {
    try {
      friendList = await serverConnect.getFriendList();
    } catch (e) {
      if (kDebugMode) {
        if (mounted) ErrorDialog.showErrorDialog(context, e.toString());
        friendList.add(ChatUsers("test", 1, 1, null));
        setState(() {});
      }
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          getUpperBar(context),
          Padding(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search...",
                hintStyle: TextStyle(color: Colors.grey.shade600),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.all(8),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey.shade100)),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: friendList.length,
              padding: const EdgeInsets.only(top: 16),
              itemBuilder: (context, index) {
                return FriendList(
                  friend: friendList[index],
                  serverConnect: serverConnect,
                  chatTTS: widget.chatTTS,
                  focusedChatroomManager: widget.focusedChatroomManager,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
