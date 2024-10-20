import 'package:flutter/material.dart';
import 'package:nfc_reader/messageScreens/baseScreen.dart';

class APIErrorScreen extends StatefulWidget {
  const APIErrorScreen({super.key});

  @override
  State<APIErrorScreen> createState() => _APIErrorScreenState();
}

class _APIErrorScreenState extends State<APIErrorScreen> {
  @override
  Widget build(BuildContext context) {
    return const BaseScreen(text: "An error has ocurred", color: Color.fromRGBO(255, 217, 0, 1), icon: Icons.warning, secondColor: Colors.white);
  }
}