import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

class ChatUsers {
  String name;
  int id;
  int chatroomId;
  Uint8List? image;

  ChatUsers(this.name, this.id, this.chatroomId, String? base64) {
    if (base64 != null) {
      image = imageFromBase64String(base64);
    }
  }

  Uint8List? imageFromBase64String(String base64String) {
    if (base64String.isEmpty) {
      return null;
    }
    return base64Decode(base64String);
  }
}
