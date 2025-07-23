import 'package:flutter/material.dart';

void showCustomSnackBar(BuildContext context, String message,
    {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message,style: TextStyle(color: Colors.white70),),
      backgroundColor: isError ? Colors.red : Colors.black87,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
