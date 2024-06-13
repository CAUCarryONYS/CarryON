import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'models/chatroomModel.dart';

class FocusedChatroomManager {
  static const String filename = "focus_chatroom_list.json";
  Queue<Chatroom> focusChatroomId = Queue();
  Queue<Chatroom> nowFocus = Queue();
  int index = 0;
  File? file;
  FocusedChatroomManager() {
    loadFile();
  }

  bool focus(Chatroom chatroom) {
    if (focusChatroomId.length >= 3) {
      focusChatroomId.removeFirst();
    }
    for (var element in focusChatroomId) {
      if (element.chatRoomId == chatroom.chatRoomId) return false;
    }
    focusChatroomId.add(chatroom);
    showNow();
    return true;
  }

  int getNumOfNext(int chatroomId) {
    int ret = -1;

    for (int i = 0; i < nowFocus.length; i++) {
      if (nowFocus.elementAt(i).chatRoomId == chatroomId) {
        ret = i - index;
        if (ret < 0) {
          ret += nowFocus.length;
        }
        break;
      }
    }
    return ret;
  }

  void unfocus(Chatroom chatroom) {
    focusChatroomId.removeWhere((index) {
      return index.chatRoomId == chatroom.chatRoomId;
    });
  }

  void enter(Chatroom chatroom) {
    index = 0;
    nowFocus.clear();
    nowFocus.addAll(focusChatroomId);
    nowFocus.removeWhere((index) {
      return index.chatRoomId == chatroom.chatRoomId;
    });
    nowFocus.addFirst(chatroom);
    index = 0;
  }

  Chatroom getNext() {
    index = (index + 1) % nowFocus.length;
    return nowFocus.elementAt(index);
  }

  Chatroom get now => nowFocus.elementAt(index);

  bool isFocused(int chatroomId) {
    for (var element in focusChatroomId) {
      if (element.chatRoomId == chatroomId) return true;
    }
    return false;
  }

  String listToJson(List<Chatroom> chatrooms) =>
      jsonEncode(chatrooms.map((i) => i.toJson()).toList()).toString();

  void showNow() {
    print(focusChatroomId.length);
    print(focusChatroomId.toString());
  }

  void saveFile() async {
    String jsonString = listToJson(focusChatroomId.toList());
    if (file == null) {
      final directory = await getApplicationDocumentsDirectory();
      const path = '/$filename';
      file = File(directory.path + path);
    }
    file!.writeAsString(jsonString);
  }

  void loadFile() async {
    String jsonString;
    try {
      if (file == null) {
        final directory = await getApplicationDocumentsDirectory();
        const path = '/$filename';
        file = File(directory.path + path);
      }
      jsonString = await file!.readAsString();
      List<dynamic> listFromJson = jsonDecode(jsonString);
      for (var i in listFromJson) {
        focusChatroomId.add(Chatroom.fromJson(i));
      }
    } catch (e) {
      print(e.toString());
      return;
    }
  }
}
