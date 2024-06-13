import 'package:flutter/material.dart';

class Button1 extends StatelessWidget {
  String btText;
  Color btColor;
  final Function()? onTap;
  Button1(
      {super.key,
      required this.onTap,
      required this.btText,
      required this.btColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(25),
        margin: const EdgeInsets.symmetric(horizontal: 25),
        decoration: BoxDecoration(
          color: btColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            btText,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
