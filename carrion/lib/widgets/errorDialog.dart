
import 'package:flutter/material.dart';

class ErrorDialog{
 static void showErrorDialog(BuildContext context, String error){
  showDialog(context: context, 
  builder: (BuildContext context) => AlertDialog(
    title: Text("Error Ocurred"),
    content: Text(error.replaceAll("Exception: ", "")),
  )
  );
 } 
}