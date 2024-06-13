import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatSocket {
  static const String url = 'ws://copytixe.iptime.org:8085/ws/';
  final int myId;
  final int friendId;

  late WebSocketChannel channel;

  ChatSocket(this.myId, this.friendId) {
    channel = IOWebSocketChannel.connect(url + friendId.toString());
  }

  void sendMessage(String message) {
    String body = json
        .encode({"senderId": myId, "message": message, "chatRoomId": friendId});
    print(body);
    channel.sink.add(body);
  }
}
