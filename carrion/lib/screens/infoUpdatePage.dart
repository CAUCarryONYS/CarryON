import '/loginManager.dart';
import '../tts.dart';
import '../widgets/errorDialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../server/server_connect.dart';
import '../../widgets/loginTextfield.dart';
import '../../screens/homePage.dart';

class InfoUpdatePage extends StatefulWidget {
  InfoUpdatePage({super.key, required this.serverConnect});
  ServerConnect serverConnect;

  @override
  State<InfoUpdatePage> createState() => _InfoUpdatePageState();
}

class _InfoUpdatePageState extends State<InfoUpdatePage> {
  bool passwordsMatch = true;
  bool isSignUpButtonActive = false;
  ServerConnect get serverConnect => widget.serverConnect;
  bool isProfileChanged = false;

  final idController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final reEnterPasswordController = TextEditingController();
  XFile? _image;


  @override
  void initState() {
    super.initState();
    usernameController.addListener(_updateButtonState);
    passwordController.addListener(_updateButtonState);
    reEnterPasswordController.addListener(_updateButtonState);
    idController.text=serverConnect.id;
    
  }

  void _updateButtonState() {
    setState(() {
        passwordsMatch = passwordController.text == reEnterPasswordController.text;
        isSignUpButtonActive = usernameController.text.isNotEmpty &&
            passwordController.text.isNotEmpty &&
            reEnterPasswordController.text.isNotEmpty &&
            passwordsMatch;
    });
  }
  


  void registerUserIn(BuildContext context) async {
    var name = usernameController.text;
    var password = passwordController.text;

    //if (name.isEmpty || password.isEmpty || reEnterPasswordController.text.isEmpty) {
      if (name.isEmpty) {
        name=serverConnect.myName;
      }
    //   
    if(password.isEmpty&&reEnterPasswordController.text.isEmpty){
      password = serverConnect.myPassword;
    }

    if (!passwordsMatch) {
      ErrorDialog.showErrorDialog(context, "비밀번호가 일치하지 않습니다.");
      return;
    }

    String? profileImage;

    if(isProfileChanged){
      if (_image == null) {
        profileImage = null;
      } else {
        Uint8List? buffer = await FlutterImageCompress.compressWithFile(
          _image!.path,
          quality: 50,
        );
        profileImage = buffer == null ? null : base64Encode(buffer);
      }
    } else{
      profileImage = serverConnect.profileImage;
    }

    var isSuccess = await serverConnect.updateUserInfo(name, password, profileImage);

    
      if (isSuccess) {
        setState(() {
          usernameController.clear();
          passwordController.clear();
          reEnterPasswordController.clear();
        });
      } else {
        // 팝업 넣기
      }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = image;
    });
    isProfileChanged = true;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                const Text(
                  "CarriOn",
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff26408B)),
                ),
                const Text(
                  '보다 안전한 메시지',
                  style: TextStyle(
                      color: Color(0xff0E0536),
                      fontSize: 18,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 50),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 30),
                      
                        InkWell(
                          onTap: _pickImage,
                          child: Column(
                            children: [
                              (!isProfileChanged||serverConnect.profileImage==null)?(_image == null
                                  ? const Text(
                                '프로필 사진 등록',
                                style: TextStyle(
                                  color: Color(0xff26408B),
                                ),
                              )
                                  : Image.file(
                                File(_image!.path),
                                height: 150,
                              )):Image.memory(base64Decode(serverConnect.profileImage!)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          readOnly: true,
                          controller: idController,
                          decoration: const InputDecoration(
                            labelText: 'ID',
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Stack(
                          alignment: Alignment.centerRight,
                          children: [
                            TextField(
                              controller: reEnterPasswordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Re-enter Password',
                                border: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: passwordsMatch ? Colors.grey : Colors.red,
                                  ),
                                ),
                              ),
                            ),
                            if (!passwordsMatch)
                              const Padding(
                                padding: EdgeInsets.only(right: 10, top: 5),
                                child: Text(
                                  '비밀번호가 일치하지 않습니다.',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: isSignUpButtonActive ? () => registerUserIn(context) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSignUpButtonActive ? const Color(0xff26408B) : Colors.grey,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Update',
                            style: TextStyle(
                              fontSize: 18,
                              color: isSignUpButtonActive ? Colors.white : Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                  
                    
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
