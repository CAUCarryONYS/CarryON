import 'package:flutter/material.dart';

class LoginTextField extends StatelessWidget {
  static void emptyFunction(){}
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  Function function;

  LoginTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    this.function = LoginTextField.emptyFunction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: TextField(
        onSubmitted: (text)=>function(),
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.black,
            ),
          ),
          fillColor: const Color(0xffB3C4D8),
          filled: true,
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Colors.black45,
          ),
        ),
      ),
    );
  }
}
