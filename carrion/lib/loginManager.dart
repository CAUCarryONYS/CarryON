import 'dart:convert';
import 'dart:io';

import '../server/server_connect.dart';
import 'package:path_provider/path_provider.dart';

class LoginManager {
  static const filename = "autoLoginData.json";
  File? file;
  ServerConnect? serverConnect;

  String? loginId;
  String? password;
  bool? isAutoLogin;
  bool? isSaveId;

  LoginManager({this.loginId, this.password, this.isAutoLogin, this.isSaveId, required this.serverConnect});

  LoginManager.fromJson(Map<String, dynamic> json) {
    loginId = json['loginId'];
    password = json['password'];
    isAutoLogin = json['isAutoLogin'];
    isSaveId = json['isSaveId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['loginId'] = this.loginId;
    data['password'] = this.password;
    data['isAutoLogin'] = this.isAutoLogin;
    data['isSaveId'] = this.isSaveId;
    return data;
  }

  void saveFile() async {
    String jsonString = jsonEncode(toJson());
    if (file == null) {
      final directory = await getApplicationDocumentsDirectory();
      const path = '/$filename';
      file = File(directory.path + path);
    }
    file!.writeAsString(jsonString);
  }
  Future<bool> loadFile() async{
    String jsonString;
    try {
      if (file == null) {
        final directory = await getApplicationDocumentsDirectory();
        const path = '/$filename';
        file = File(directory.path + path);
      }
      jsonString = await file!.readAsString();
      var json = jsonDecode(jsonString);
      loginId = json['loginId'];
      password = json['password'];
      isAutoLogin = json['isAutoLogin'];
    } catch(e){
      return false;
    }
    return true;
  }
  Future<bool> login() async{
    
    var isSuccess = false;
    try {
      isSuccess = await serverConnect!.login(loginId!, password!);
      
    } catch (e) {
      isSuccess=false;
    }
    saveFile();
    return isSuccess;
  }
}