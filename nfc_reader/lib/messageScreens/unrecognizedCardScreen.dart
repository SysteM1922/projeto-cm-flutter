import 'package:flutter/material.dart';
import 'package:nfc_reader/messageScreens/baseScreen.dart';

class UnrecognizedCardScreen extends StatefulWidget {
  const UnrecognizedCardScreen({super.key});

  @override
  State<UnrecognizedCardScreen> createState() => _UnrecognizedCardScreenState();
}

class _UnrecognizedCardScreenState extends State<UnrecognizedCardScreen> {
  @override
  Widget build(BuildContext context) {
    return const BaseScreen(text: "Card not recognized", color: Color.fromRGBO(255, 0, 0, 1), icon: Icons.credit_card_off, secondColor: Colors.white);
  }
}