import 'dart:async';

import '../models/chatroomModel.dart';

import '../focusedChatroomManager.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/chatUserModel.dart';
import '../server/server_connect.dart';
import 'package:flutter/material.dart';
import '../tts.dart';
import '../ui.dart';

class FriendList extends StatefulWidget {
  ChatUsers friend;

  ServerConnect serverConnect;
  TTS chatTTS;
  FocusedChatroomManager focusedChatroomManager;
  FriendList(
      {super.key,
      required this.friend,
      required this.serverConnect,
      required this.chatTTS,
      required this.focusedChatroomManager});
  @override
  _FriendListState createState() => _FriendListState();
}

class _FriendListState extends State<FriendList> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          /*
          return ChatDetailPage(
            name: widget.name,
            friendId: widget.id,
            serverConnect: widget.serverConnect,
          );
          */
          return ChatUI(
            title: widget.friend.name,
            recipientId: widget.friend.id,
            myId: widget.serverConnect.primaryKey,
            serverConnect: widget.serverConnect,
            chatroom: Chatroom(
              chatRoomId: widget.friend.chatroomId,
              chatroomName: widget.friend.name,
              participantId: [widget.friend.id],
              participantName: [widget.friend.name],
              latestMessage: "",
              latestMessageSenderId: widget.friend.id,
              lastMessageSenderName: "",
              lastMessageTimestamp: null,
              imageStr: [],
            ),
            chatroomId: widget.friend.chatroomId,
            chatTts: widget.chatTTS,
            focusedChatroomManager: widget.focusedChatroomManager,
          );
        }));
      },
      child: Container(
        padding:
            const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 10),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Row(
                children: <Widget>[
                  getAvatar(35),
                  const SizedBox(
                    width: 30,
                  ),
                  Expanded(
                    child: Container(
                      color: Colors.transparent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.friend.name,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(
                            height: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  CircleAvatar getAvatar(double radius){
    ImageProvider<Object> ip;
    if(widget.friend.image == null){
      ip = const AssetImage('assets/image.png');
    } else{
      ip = MemoryImage(widget.friend.image!);
    }
    return CircleAvatar(
                    backgroundImage: ip,
                    maxRadius: 35,
                  );
  }

}
