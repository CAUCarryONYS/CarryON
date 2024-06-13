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

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.tts});
  final TTS tts;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLogin = true;
  bool isAutoLogin = false;
  bool isLoginButtonActive = false;
  bool isSignUpButtonActive = false;
  bool passwordsMatch = true;

  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final reEnterPasswordController = TextEditingController();
  XFile? _image;

  ServerConnect serverConnect = ServerConnect();

  @override
  void initState() {
    super.initState();
    usernameController.addListener(_updateButtonState);
    emailController.addListener(_updateButtonState);
    passwordController.addListener(_updateButtonState);
    reEnterPasswordController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    setState(() {
      if (isLogin) {
        isLoginButtonActive = usernameController.text.isNotEmpty && passwordController.text.isNotEmpty;
      } else {
        passwordsMatch = passwordController.text == reEnterPasswordController.text;
        isSignUpButtonActive = usernameController.text.isNotEmpty &&
            emailController.text.isNotEmpty &&
            passwordController.text.isNotEmpty &&
            reEnterPasswordController.text.isNotEmpty &&
            passwordsMatch;
      }
    });
  }

  void signUserIn(BuildContext context) async {
    var id = usernameController.text;
    var password = passwordController.text;
    if (id.isEmpty || password.isEmpty) {
      if (id.isEmpty) {
        ErrorDialog.showErrorDialog(context, "ID를 입력하세요.");
      }
      if (password.isEmpty) {
        ErrorDialog.showErrorDialog(context, "Password를 입력하세요.");
      }
      return;
    }

    LoginManager loginManager = LoginManager(
        serverConnect: serverConnect,
        loginId: id,
        password: password,
        isAutoLogin: isAutoLogin);

    try {
      widget.tts.loadFile();
      await loginManager.login();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => HomePage(
              serverConnect: serverConnect,
              chatTTS: widget.tts,
            )),
      );
    } catch (e) {
      ErrorDialog.showErrorDialog(context, e.toString());
      return;
    }
  }

  void registerUserIn(BuildContext context) async {
    var name = usernameController.text;
    var id = emailController.text;
    var password = passwordController.text;

    if (name.isEmpty || id.isEmpty || password.isEmpty || reEnterPasswordController.text.isEmpty) {
      if (name.isEmpty) {
        ErrorDialog.showErrorDialog(context, "Username을 입력하세요.");
      }
      if (id.isEmpty) {
        ErrorDialog.showErrorDialog(context, "Email을 입력하세요.");
      }
      if (password.isEmpty) {
        ErrorDialog.showErrorDialog(context, "비밀번호를 입력하세요.");
      }
      if (reEnterPasswordController.text.isEmpty) {
        ErrorDialog.showErrorDialog(context, "비밀번호를 다시 입력하세요.");
      }
      return;
    }

    if (!passwordsMatch) {
      ErrorDialog.showErrorDialog(context, "비밀번호가 일치하지 않습니다.");
      return;
    }

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
        setState(() {
          isLogin = true;
          usernameController.clear();
          emailController.clear();
          passwordController.clear();
          reEnterPasswordController.clear();
        });
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

  void toggleFormMode() {
    setState(() {
      isLogin = !isLogin;
      usernameController.clear();
      emailController.clear();
      passwordController.clear();
      reEnterPasswordController.clear();
    });
    _updateButtonState();
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () {
                              if (!isLogin) toggleFormMode();
                            },
                            child: Text(
                              'LOGIN',
                              style: TextStyle(
                                fontSize: isLogin ? 30 : 20,
                                fontWeight: isLogin ? FontWeight.bold : FontWeight.normal,
                                color: isLogin ? Colors.black : Colors.grey,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              if (isLogin) toggleFormMode();
                            },
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: isLogin ? 20 : 30,
                                fontWeight: isLogin ? FontWeight.normal : FontWeight.bold,
                                color: isLogin ? Colors.grey : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      if (isLogin) ...[
                        TextField(
                          controller: usernameController,
                          decoration: InputDecoration(
                            labelText: 'ID',
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                          ),
                        ),
                        Checkbox(
                            value: isAutoLogin,
                            onChanged: (bool? value) {
                              setState(() {
                                isAutoLogin = value ?? false;
                              });
                            }),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: isLoginButtonActive ? () => signUserIn(context) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff26408B),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 18,
                              color: isLoginButtonActive ? Colors.white : Colors.grey[700],
                            ),
                          ),
                        ),
                      ] else ...[
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
                          controller: usernameController,
                          decoration: InputDecoration(
                            labelText: 'ID',
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
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
                          decoration: InputDecoration(
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
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 18,
                              color: isSignUpButtonActive ? Colors.white : Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
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
