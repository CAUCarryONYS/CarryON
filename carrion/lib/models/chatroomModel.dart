import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:merge_images/merge_images.dart';
import 'package:intl/intl.dart';

class Chatroom {
  late int chatRoomId;
  late String? chatroomName;
  late List<int> participantId;
  late List<String> participantName;
  String? latestMessage;
  int? latestMessageSenderId;
  String? lastMessageSenderName;
  String? lastMessageTimestamp;
  bool isFocused = false;
  List<Uint8List?> imageList = List.empty(growable: true);
  List<String> imageStr = [];

  Chatroom({
    required this.chatRoomId,
    this.chatroomName,
    required this.participantId,
    required this.participantName,
    required this.latestMessage,
    required this.latestMessageSenderId,
    required this.lastMessageSenderName,
    required this.lastMessageTimestamp,
    this.isFocused = false,
    required this.imageStr,
  }) {
    for (var element in imageStr) {
      imageList.add(imageFromBase64String(element));
    }
  }
  Chatroom.fromJson(Map<String, dynamic> json) {
    chatRoomId = json['chatRoomId'];
    chatroomName = json['chatroomName'];
    participantId = json['participantId'].cast<int>();
    latestMessage = json['latestMessage'];
    latestMessageSenderId = json['latestMessageSenderId'];
    lastMessageSenderName = json['lastMessageSenderName'];
    lastMessageTimestamp = json['lastMessageTimestamp'];
    isFocused = json['isFocused'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['chatRoomId'] = this.chatRoomId;
    data['chatroomName'] = this.chatroomName;
    data['participantId'] = this.participantId;
    data['latestMessage'] = this.latestMessage;
    data['latestMessageSenderId'] = this.latestMessageSenderId;
    data['lastMessageSenderName'] = this.lastMessageSenderName;
    data['lastMessageTimestamp'] = this.lastMessageTimestamp;
    data['isFocused'] = this.isFocused;
    return data;
  }

  Uint8List? imageFromBase64String(String base64String) {
    if (base64String.isEmpty) {
      return null;
    }
    return base64Decode(base64String);
  }

  String getNames(String myname) {
    if (participantId.length > 2 && chatroomName != null) return chatroomName!;
    String name = "";
    for (var element in participantName) {
      if (element != myname) {
        name += "$element, ";
      }
    }
    name = name.substring(0, name.length - 2);
    return name;
  }

  String getTimeString() {
    String ret = "";
    if (lastMessageTimestamp != null) {
      var last = DateTime.parse(lastMessageTimestamp!);
      var now = DateTime.now();

      last = last.add(const Duration(hours: 9));

      if (last.day < now.day) {
        ret = DateFormat.Md('en_US').format(last);
      } else {
        ret = DateFormat.jm('en_US').format(last);
      }
    }
    return ret;
  }

  void focus() {
    isFocused = true;
  }

  void unfocuse() {
    isFocused = false;
  }

  Future<List<Uint8List?>> getImage(int myId) async {
    List<Uint8List?> ret = List.empty(growable: true);
    if (imageList.length == 2 || true) {
      for (int i = 0; i < participantId.length; i++) {
        if (participantId[i] != myId) {
          ret.add(imageList[i]);
        }
      }
    }

    // List<ui.Image> imList = List.empty(growable: true);
    // for (int i = 0; i < participantId.length; i++) {
    //   if (participantId[i] == myId) continue;
    //   var element = imageList[i];
    //   if (element == null) {
    //     ByteData imageData = await rootBundle.load('assets/image.png');
    //     element = imageData.buffer.asUint8List();
    //   }
    //   imList.add(await ImagesMergeHelper.uint8ListToImage(element));
    // }
    // ui.Image image = await ImagesMergeHelper.margeImages(imList,
    //     fit: true, direction: Axis.horizontal);
    // Uint8List? ret = await ImagesMergeHelper.imageToUint8List(image);
    // return ret;

    return ret;
  }
}
