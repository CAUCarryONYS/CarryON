import 'dart:convert';

import 'package:carrion/screens/infoUpdatePage.dart';

import '../proper_noun_fixer.dart';
import '../server/server_connect.dart';
import '../widgets/errorDialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:flutter/material.dart';

import '../tts.dart';
import 'loginPage.dart';

class SettingPage extends StatefulWidget {
  final TTS chatTTS;
  final ServerConnect serverConnect;
  const SettingPage({super.key, required this.chatTTS, required this.serverConnect});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  late final TTS chatTTS;
  ProperNounFixer properNounFixer = ProperNounFixer();
  final originTextController = TextEditingController();
  final replacedTextController = TextEditingController();
  @override
  void initState() {
    super.initState();
    chatTTS = widget.chatTTS;
    properNounFixer.loadFile();
  }

  CircleAvatar getAvatar(double maxRadius){
    ImageProvider<Object> image;
    if (widget.serverConnect.profileImage == null) {
      image = const AssetImage('assets/image.png');
    } else {
      image = MemoryImage(base64Decode( widget.serverConnect.profileImage!));
    }
    return CircleAvatar(
      backgroundImage: image,
      maxRadius: maxRadius,
    );

  }

  SettingsSection userDataSection() {
    return SettingsSection(
      title: const Text("개인 설정"),
      tiles: [
        SettingsTile(title: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            )
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const SizedBox(height: 80,width: 1,),
                  getAvatar(40),
                  const SizedBox(width: 25,),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.serverConnect.myName,
                        style: const TextStyle(
                          fontSize: 20,
                        ),
                      ),
                      Text(widget.serverConnect.id),
                    ],
                  ),
                ],
              ),
              

              ElevatedButton(
              child: const Text("로그아웃",
                style: TextStyle(
                  fontSize: 14,
                ),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => LoginPage(tts: widget.chatTTS)),
                );
              },),
            ],
          ),
          onPressed: (){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => InfoUpdatePage(serverConnect: widget.serverConnect))
            );
          },
          )),
      ],
    );
  }

  SettingsTile properNounFixerTile() {
    return SettingsTile.navigation(
      title: const Text(""),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
              width: MediaQuery.of(context).size.width * 0.6,
              height: 40,
              child: TextField(
                controller: originTextController,
                decoration: InputDecoration(labelText: "원래 단어"),
              )),
          SizedBox(
              width: MediaQuery.of(context).size.width * 0.6,
              height: 40,
              child: TextField(
                controller: replacedTextController,
                decoration: InputDecoration(labelText: "대체 단어"),
              )),
          ElevatedButton(
              onPressed: () {
                try {
                  properNounFixer.addNoun(
                      originTextController.text, replacedTextController.text);
                  properNounFixer.saveFile();
                } catch (e) {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                            title: Text("대체 단어표"),
                            content: Text(e.toString()),
                          ));
                }
              },
              child: Text("삽입")),
          ElevatedButton(
              onPressed: () {
                try {
                  properNounFixer.showEveryNoun();
                } catch (e) {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                            title: Text("대체 단어표"),
                            content: Text(e.toString()),
                          ));
                }
              },
              child: Text("단어표 보기")),
          ElevatedButton(
              onPressed: () {
                properNounFixer.init();
                properNounFixer.saveFile();
              },
              child: Text("초기화"))
        ],
      ),
    );
  }

  SettingsTile ttsMaxSpeedTile() {
    return SettingsTile.navigation(
      title: Text("TTS 최대 속도"),
      trailing: Column(
        children: [
          Text(((chatTTS.maxSpeed * 100).round() / 100).toString()),
          Row(
            children: [
              ElevatedButton(
                  onPressed: () {
                    chatTTS.upMaxSpeed();
                    setState(() {});
                  },
                  child: const Text("빠르게")),
              ElevatedButton(
                  onPressed: () {
                    chatTTS.downMaxSpeed();
                    setState(() {});
                  },
                  child: const Text("느리게")),
            ],
          )
        ],
      ),
    );
  }

  SettingsTile ttsEngineTile() {
    return SettingsTile.navigation(
        title: FutureBuilder<dynamic>(
      future: chatTTS.getEngines(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.hasData) {
          return enginesDropDownSection(snapshot.data as List<dynamic>);
        } else if (snapshot.hasError) {
          return Text('Error loading languages...');
        } else
          return Text('Loading Languages...');
      },
    ));
  }

  SettingsTile ttsLanguageTile() {
    return SettingsTile.navigation(
        title: FutureBuilder<dynamic>(
      future: chatTTS.getLanguages(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.hasData) {
          return languageDropDownSection(snapshot.data as List<dynamic>);
        } else if (snapshot.hasError) {
          return Text('Error loading languages...');
        } else
          return Text('Loading Languages...');
      },
    ));
  }

  void changedEnginesDropDownItem(String? selectedEngine) async {
    await chatTTS.flutterTts.setEngine(selectedEngine!);
    chatTTS.language = null;
    setState(() {
      chatTTS.engine = selectedEngine;
    });
  }

  Widget enginesDropDownSection(List<dynamic> engines) => Container(
        padding: EdgeInsets.only(top: 50.0),
        child: Row(
          children: [
            
              const Text("엔진"),
              const SizedBox(width: 15,),
              DropdownButton(
          value: chatTTS.engine,
          items: chatTTS.getEnginesDropDownMenuItems(engines),
          onChanged: changedEnginesDropDownItem,
          hint: Text(chatTTS.engine ?? ""),
        ),
          ],
        ) 
      );

  void changedLanguageDropDownItem(String? selectedType) {
    setState(() {
      chatTTS.language = selectedType;
      chatTTS.flutterTts.setLanguage(chatTTS.language!);
      if (chatTTS.isAndroid) {
        chatTTS.flutterTts.isLanguageInstalled(chatTTS.language!).then(
            (value) => chatTTS.isCurrentLanguageInstalled = (value as bool));
      }
    });
    chatTTS.saveFile();
  }

  Widget languageDropDownSection(List<dynamic> languages) => Container(
      padding: EdgeInsets.only(top: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Row(mainAxisAlignment: MainAxisAlignment.start, children: [
        
        const Text("음성"),
        const SizedBox(width: 15,),
        DropdownButton(
          value: chatTTS.language,
          items: chatTTS.getLanguageDropDownMenuItems(languages),
          onChanged: changedLanguageDropDownItem,
          hint: 
              Text(chatTTS.language ?? ""),
        ),]),
        ElevatedButton(onPressed: (){chatTTS.setText("안녕하세요?");}, 
        child: const Text("예시 음성 듣기")),
      ]));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SettingsList(
          sections: [
            userDataSection(),
            SettingsSection(title: Text('TTS'), tiles: [
              ttsEngineTile(),
              ttsLanguageTile(),

              SettingsTile.navigation(title: const SizedBox(height: 10,),),
              
              ttsMaxSpeedTile(),
              SettingsTile.navigation(title: const SizedBox(height: 30,),),
            ]),
            SettingsSection(
                title: Text("대체 단어 설정"),
                tiles: [properNounFixerTile()]),
          ],
        ),
      ),
    );
  }
}
