import 'dart:async';

import '../focusedChatroomManager.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../tts.dart';

import '../screens/chatStateInterface.dart';
import '../server/server_connect.dart';
import '../ui.dart';
import '../widgets/errorDialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/chatUserModel.dart';
import '../models/chatroomModel.dart';
import 'makeChatroomPage.dart';

class ChatPage extends StatefulWidget {
  ChatPage({
    super.key,
    required this.serverConnect,
    required this.chatTTS,
    required this.focusedChatroomManager,
  });
  ServerConnect serverConnect;
  TTS chatTTS;
  FocusedChatroomManager focusedChatroomManager;

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with ChatState {
  late FocusedChatroomManager focusedChatroomManager;
  late final String myUrl;
  WebSocketChannel? _channel;
  static const AssetImage defaultImage = AssetImage('assets/image.png');
  @override
  Function get getList => getChatUserList;

  @override
  void dispose() {
    focusedChatroomManager.saveFile();
    if (_channel != null) _channel!.sink.close();
    super.dispose();
  }

  List<Chatroom> chatroomList = List.empty(growable: true);
  @override
  void initState() {
    focusedChatroomManager = widget.focusedChatroomManager;
    serverConnect = widget.serverConnect;
    myUrl = "ws://copytixe.iptime.org:8085/ws/${serverConnect.primaryKey}";
    _connectToWebSocket();
    super.initState();
    getChatUserList();
  }

  void _connectToWebSocket() async {
    _channel = WebSocketChannel.connect(Uri.parse(myUrl));
    _channel!.stream.listen(
          (message) {
        print('recieve chan Received message: $message');
        _handleReceivedMessage(message);
      },
      onError: (error) {
        print('WebSocket stream error: $error');
      },
      onDone: () {
        print('WebSocket stream closed');
      },
    );
  }

  void _handleReceivedMessage(String message) {
    getChatUserList();
    setState(() {});
  }

  void getChatUserList() async {
    try {
      chatroomList = await serverConnect.getChatroomList();
    } catch (e) {
      if (kDebugMode) {
        if (mounted) {
          ErrorDialog.showErrorDialog(context, e.toString());
          setState(() {});
        }
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  double _dragExtent = 0.0;
  bool _isSwiping = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text(
                    "CarriON",
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff26408B)),
                  ),
                  Container(
                    padding: const EdgeInsets.only(
                        left: 8, right: 8, top: 2, bottom: 2),
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.blue[50],
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context){
                          return MakeChatroomPage(
                            serverConnect: widget.serverConnect,
                          );
                        }));
                      },
                      child: const Row(
                      children: <Widget>[
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
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    ),
                  )
                ],
              ),
            ),
          ),
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
              itemCount: chatroomList.length,
              padding: const EdgeInsets.only(top: 16),
              itemBuilder: (context, index) {
                return makeChatroomView(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> pushChatroom(Chatroom chatroom) async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return ChatUI(
        title: chatroom.getNames(serverConnect.myName),
        chatroom: chatroom,
        recipientId: chatroom.participantId[0],
        myId: widget.serverConnect.primaryKey,
        serverConnect: widget.serverConnect,
        chatroomId: chatroom.chatRoomId,
        chatTts: widget.chatTTS,
        focusedChatroomManager: focusedChatroomManager,
      );
    }));
    _connectToWebSocket();
  }

  Widget makeChatroomView(int index) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dragExtent += details.primaryDelta!;
          _isSwiping = true;
        });
      },
      onHorizontalDragEnd: (details) {
        setState(() {
          if (_dragExtent.abs() > 100) {
            if (focusedChatroomManager.isFocused(chatroomList[index].chatRoomId)) {
              focusedChatroomManager.unfocus(chatroomList[index]);
            } else {
              focusedChatroomManager.focus(chatroomList[index]);
            }
          }
          _dragExtent = 0.0;
          _isSwiping = false;
        });
      },
      onTap: () {
        if (!_isSwiping) {
          pushChatroom(chatroomList[index]);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        color: focusedChatroomManager.isFocused(chatroomList[index].chatRoomId)
            ? Colors.lightGreenAccent.withOpacity(0.5)
            : Colors.transparent,
        padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 10),
        child: Row(
          children: <Widget>[
            FutureBuilder(
                future: chatroomList[index]
                    .getImage(widget.serverConnect.primaryKey),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if ((!snapshot.hasData) || snapshot.hasError) {
                    return const CircleAvatar(
                      backgroundImage: AssetImage('assets/image.png'),
                      maxRadius: 30,
                    );
                  } else {
                    List<Uint8List?> data = snapshot.data;

                    if (data.isEmpty || data[0] == null) {
                      return const CircleAvatar(
                        backgroundImage: AssetImage('assets/image.png'),
                        maxRadius: 35,
                      );
                    }
                    if (data.length == 1) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(
                            width: 14,
                          ),
                          Align(
                            widthFactor: 0.5,
                            child: CircleAvatar(
                              backgroundImage: MemoryImage(data[0]!),
                              maxRadius: 40,
                            ),
                          ),
                          const SizedBox(width: 15,)
                        ],
                      );
                    }
                    if (data.length == 2) {
                      double radius = 27.5;
                      double heightfac = 0.65;
                      return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Align(
                                heightFactor: heightfac,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Align(
                                        widthFactor: 0.77,
                                        child: getAvatar(data[0], radius)),
                                    Align(
                                        widthFactor: 1,
                                        child: SizedBox(
                                          width: radius,
                                          height: radius,
                                        )),
                                  ],
                                )),
                            Align(
                                heightFactor: heightfac,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Align(
                                        widthFactor: 1,
                                        child: SizedBox(
                                          width: radius,
                                          height: radius,
                                        )),
                                    Align(
                                        widthFactor: 0.5,
                                        child: getAvatar(data[1], radius)),
                                  ],
                                )),
                          ]);
                    }
                    if (data.length == 3) {
                      double radius = 25;
                      double heightfac = 0.7;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Align(
                            heightFactor: heightfac,
                            widthFactor: 0.5,
                            child: getAvatar(data[0], radius),
                          ),
                          Align(
                              heightFactor: heightfac,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (int i = 1; i < data.length; i++)
                                    Align(
                                        widthFactor: 0.7,
                                        child: getAvatar(data[i], radius)),
                                ],
                              ))
                        ],
                      );
                    }
                    if (data.length >= 4) {
                      double radius = 18;
                      double heightfac = 0.8;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Align(
                            heightFactor: heightfac,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (int i = 0; i < 2; i++)
                                  Align(
                                      heightFactor: 0.5,
                                      widthFactor: 0.5,
                                      child: getAvatar(data[i], radius)),
                              ],
                            ),
                          ),
                          Align(
                              heightFactor: heightfac,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (int i = 2; i < 4; i++)
                                    Align(
                                        widthFactor: 0.5,
                                        child: getAvatar(data[i], radius)),
                                ],
                              ))
                        ],
                      );
                    }
                    return const CircleAvatar(
                      backgroundImage: AssetImage('assets/image.png'),
                      maxRadius: 30,
                    );
                  }
                }),
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
                      chatroomList[index].getNames(serverConnect.myName),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    Text(
                      chatroomList[index].latestMessage ?? "",
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: false
                              ? FontWeight.bold
                              : FontWeight.normal),
                    ),
                  ],
                ),
              ),
            ),
            Text(
              chatroomList[index].getTimeString(),
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: false ? FontWeight.bold : FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }

  static CircleAvatar getAvatar(Uint8List? data, double maxRadius) {
    ImageProvider<Object> image;
    if (data == null) {
      image = defaultImage;
    } else {
      image = MemoryImage(data!);
    }
    return CircleAvatar(
      backgroundImage: image,
      maxRadius: maxRadius,
    );
  }
}
