import 'dart:convert';
import 'dart:io';

import '../widgets/errorDialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

import '../../server/server_connect.dart';
import '../../widgets/loginTextfield.dart';
import '../../screens/homePage.dart';
import '../tts.dart';
import './loginPage.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, required this.tts});
  final TTS tts;

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final usernameController = TextEditingController();
  final idController = TextEditingController();
  final passwordController = TextEditingController();
  final reEnterPasswordController = TextEditingController();
  XFile? _image;

  void registerUserIn(BuildContext context) async {
    var name = usernameController.text;
    var id = idController.text;
    var password = passwordController.text;
    String? profileImage;

    if (_image == null) {
      profileImage = null;
    } else {
      Uint8List? buffer = await FlutterImageCompress.compressWithFile(
        _image!.path,
        quality: 50,
      );
      profileImage = buffer == null ? null : base64Encode(buffer);
    }

    var registration = RegistrationAPI(
      id,
      name,
      password,
      profileImage,
    );
    if (profileImage != null) print(profileImage!.length);

    try {
      await registration.get();
      if (registration.isSuccess) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage(tts: widget.tts)),
        );
      } else {
        throw registration.data['error'];
      }
    } catch (e) {
      if (kDebugMode) {
        print("cannot registrate.");
        print(e);
      }
      ErrorDialog.showErrorDialog(context, e.toString());
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = image;
    });
  }

  void navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage(tts: widget.tts)),
    );
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
                const SizedBox(height: 50),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: navigateToLogin,
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: null,
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      InkWell(
                        onTap: _pickImage,
                        child: Column(
                          children: [
                            _image == null
                                ? const Text(
                              '프로필 사진 등록',
                              style: TextStyle(
                                color: Color(0xff26408B),
                              ),
                            )
                                : Image.file(
                              File(_image!.path),
                              height: 150,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: idController,
                        decoration: InputDecoration(
                          labelText: 'ID',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: reEnterPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Re-enter Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () => registerUserIn(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff26408B),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(fontSize: 18),
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
