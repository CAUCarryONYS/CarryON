import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';

class ProperNoun {
  late String originText;
  late String replacedText;

  ProperNoun({
    required this.originText,
    required this.replacedText,
  });

  factory ProperNoun.fromJson(Map<String, dynamic> json) => ProperNoun(
      originText: json["originText"], replacedText: json["replacedText"]);

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["originText"] = originText;
    data["replacedText"] = replacedText;
    return data;
  }
}

class ProperNounFixer {
  static const String filename = "proper_noun_dictionary.json";
  File? file;
  List<ProperNoun>? dic;

  ProperNounFixer({this.dic});

  factory ProperNounFixer.fromJson(String jsonString) {
    List<dynamic> listFromJson = json.decode(jsonString);
    List<ProperNoun> pn = <ProperNoun>[];

    pn = listFromJson
        .map((properNoun) => ProperNoun.fromJson(properNoun))
        .toList();

    return ProperNounFixer(dic: pn);
  }
  Future<void> init() async {
    final jsonString = await rootBundle.loadString("assets/$filename");
    List<dynamic> listFromJson = json.decode(jsonString);

    dic = listFromJson
        .map((properNoun) => ProperNoun.fromJson(properNoun))
        .toList();
  }

  String fix(String input) {
    if (dic == null) {
      return input;
    }

    String output = " $input";

    for (var properNoun in dic!) {
      output =
          output.replaceAll(properNoun.originText, properNoun.replacedText);
    }
    output = output.substring(1);

    return output;
  }

  void addNoun(String ori, String rpl) {
    if (dic == null) {
      dic = <ProperNoun>[ProperNoun(originText: ori, replacedText: rpl)];
      return;
    }
    if (ori == rpl) throw "same text";

    if (ori.length < 2) throw "origin text must longer than 1.";

    ori = " $ori";
    rpl = " $rpl";
    for (var properNoun in dic!) {
      if (properNoun.originText == ori) {
        throw "duplicated origin text";
      }
      if (properNoun.replacedText == ori || properNoun.originText == rpl) {
        throw "replaced text cannot be origin text";
      }
    }
    dic!.add(ProperNoun(originText: ori, replacedText: rpl));
  }

  void removeNoun(String noun) {
    if (dic == null) {
      return;
    }
    dic?.removeWhere((item) => item.originText == noun);
  }

  void showEveryNoun() {
    String ret = "";
    if (dic == null) throw "no element";
    for (var element in dic!) {
      ret +=
          "${element.originText.substring(1)} -> ${element.replacedText.substring(1)}\n";
    }
    throw ret;
  }

  void saveFile() async {
    if (dic == null) return;
    List<Map<String, dynamic>> jsonlist = List.empty(growable: true);
    for (var element in dic!) {
      jsonlist.add(element.toJson());
    }
    var jsonString = json.encode(jsonlist);
    file = await getFile();
    file!.writeAsString(jsonString);
    print("save at ${file!.path}");
  }

  Future<File> getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    const path = '/$filename';
    return File(directory.path + path);
  }

  void loadFile() async {
    String jsonString;
    try {
      file = await getFile();
      jsonString = await file!.readAsString();
    } catch (e) {
      init();
      print(e.toString());
      return;
    }
    List<dynamic> listFromJson = json.decode(jsonString);

    dic = listFromJson
        .map((properNoun) => ProperNoun.fromJson(properNoun))
        .toList();
  }
}
