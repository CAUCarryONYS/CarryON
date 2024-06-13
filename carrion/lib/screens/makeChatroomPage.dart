import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/chatUserModel.dart';
import '../server/server_connect.dart';

class MakeChatroomPage extends StatefulWidget {
  MakeChatroomPage({super.key, required this.serverConnect});
  ServerConnect serverConnect;

  @override
  State<MakeChatroomPage> createState() => _MakeChatroomPageState();
}

class _MakeChatroomPageState extends State<MakeChatroomPage> {
  ServerConnect get serverConnect => widget.serverConnect;

  final chatroomNameController = TextEditingController();

  bool _isChanged = false;

  List<ChatUsers>? chatUserList;
  List<bool>? selectList;
  List<ChatUsers> getSelectedUserList(){
    List<ChatUsers> su = List.empty(growable: true);
    for (int i=0;i<chatUserList!.length;i++) {
      if(selectList![i]){
        su.add(chatUserList![i]);
      }
    }
    return su;
  }
  String getDefaultName(){
    if(chatUserList==null) return "";
    if(chatUserList!.isEmpty) return "";
    String ret = "";
    final selectedUserList = getSelectedUserList();
    for(int i = 0; i<selectedUserList.length;i++){
      ret += "${selectedUserList[i].name}, ";
    }
    ret = ret.substring(0,ret.length-2);
    return ret;
  }

  @override void initState() {
    getChatUserList();
    super.initState();
  }
  Future<void> getChatUserList() async{
    chatUserList = await serverConnect.getFriendList();
    setState(() {
      selectList = List.filled(chatUserList!.length, false);
    });
  }
  
  Widget makeChatuserView(int index){
    var user = chatUserList![index];
    return GestureDetector(
      onTap: () {
        selectList![index] = !selectList![index];
        if(!_isChanged){
          chatroomNameController.text = getDefaultName();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        color: selectList![index]
          ? Colors.lightGreenAccent.withOpacity(0.5)
          : Colors.transparent,
        child: Row(
          children: [
            getAvatar(user.image, 30),
            Text(user.name),
          ],
        ),
      )
    );
  }
  static CircleAvatar getAvatar(Uint8List? data, double maxRadius) {
    ImageProvider<Object> image;
    if (data == null) {
      image = const AssetImage('assets/image.png');
    } else {
      image = MemoryImage(data);
    }
    return CircleAvatar(
      backgroundImage: image,
      maxRadius: maxRadius,
    );
  }



  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("채팅방 추가하기"),
      content: Column(
        children: [
          TextField(
            controller: chatroomNameController,
            onChanged: (_){
              _isChanged = true;
            },
          ),

          if (chatUserList!=null)
            Expanded(child: ListView.builder(
              itemCount: chatUserList!.length,
              itemBuilder: (context, index){
                return makeChatuserView(index);
            }))
          else
            const Text("loading"),
        ],
      ),
    );
  }


}