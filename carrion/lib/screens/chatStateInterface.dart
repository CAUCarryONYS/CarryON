import 'dart:collection';

import '../server/server_connect.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';

mixin ChatState {
  late ServerConnect serverConnect;
  late Function getList;

  final friendNameController = TextEditingController();

  Future<dynamic> showAddFriendDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              title: Text("친구 추가하기"),
              content: TextField(
                controller: friendNameController,
              ),
              actions: [
                ElevatedButton(
                    onPressed: () => {
                          _addFriend(friendNameController.text),
                          Navigator.of(context).pop(),
                        },
                    child: Text("추가하기"))
              ],
            ));
  }

  Future<void> _addFriend(String friendId) async {
    await serverConnect.addFriends(friendId);
    getList();
  }

  Widget addFriendWidget() {
    return const Row(children: <Widget>[
      Icon(
        Icons.add,
        color: Colors.blue,
        size: 20,
      ),
      SizedBox(
        width: 2,
      ),
      Text(
        "추가하기",
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      )
    ]);
  }

  Widget getLogoWidget() {
    return const Text(
      "CarriON",
      style: TextStyle(
          fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xff26408B)),
    );
  }

  Widget getUpperBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            getLogoWidget(),
            Container(
                padding:
                    const EdgeInsets.only(left: 8, right: 8, top: 2, bottom: 2),
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.blue[50],
                ),
                child: InkWell(
                  onTap: () {
                    showAddFriendDialog(context);
                  },
                  child: addFriendWidget(),
                ))
          ],
        ),
      ),
    );
  }
}
