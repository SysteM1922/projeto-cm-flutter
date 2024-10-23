import 'package:flutter/material.dart';
import 'package:nfc_reader/messageScreens/baseScreen.dart';

class SuccessScreen extends StatefulWidget {
  const SuccessScreen({super.key, required this.extraText});

  final String extraText;

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  @override
  Widget build(BuildContext context) {
    return BaseScreen(text: "Success", color: const Color.fromARGB(255, 45, 196, 45), icon: Icons.check, secondColor: Colors.white, extraText: widget.extraText);
  }
}