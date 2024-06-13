import 'dart:async';

import 'package:flutter_feather_icons/flutter_feather_icons.dart';

import '../focusedChatroomManager.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../tts.dart';
import 'package:flutter/foundation.dart';

import '../server/server_connect.dart';
import 'package:flutter/material.dart';
import '../models/chatUserModel.dart';
import '../models/chatroomModel.dart';
import 'chatPage.dart';
import './friendsPage.dart';
import './settingPage.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key, required this.serverConnect, required this.chatTTS});
  final ServerConnect serverConnect;
  TTS chatTTS;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final List<Widget> _widgetOptions = List.empty(growable: true);
  final streamController = StreamController.broadcast();
  TTS get chatTTS => widget.chatTTS;
  FocusedChatroomManager focusedChatroomManager = FocusedChatroomManager();

  @override
  void initState() {
    super.initState();
    _widgetOptions.add(ChatPage(
      serverConnect: widget.serverConnect,
      chatTTS: chatTTS,
      focusedChatroomManager: focusedChatroomManager,
    ));
    _widgetOptions.add(friendPage(
      serverConnect: widget.serverConnect,
      chatTTS: chatTTS,
      focusedChatroomManager: focusedChatroomManager,
    ));
    _widgetOptions.add(SettingPage(chatTTS: chatTTS,serverConnect: widget.serverConnect,));
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildIcon(IconData icon, int index) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(icon),
        if (_selectedIndex == index)
          Transform.translate(
            offset: Offset(0, 25), // 점의 위치를 조정
            child: Icon(
              Icons.circle,
              size: 6,
              color: const Color(0xff26408B),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: const Color(0xff26408B),
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: _buildIcon(FeatherIcons.messageSquare, 0),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon(FeatherIcons.user, 1),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon(FeatherIcons.settings, 2),
            label: '',
          ),
        ],
      ),
    );
  }
}
