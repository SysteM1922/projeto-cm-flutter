import 'package:flutter/material.dart';
import 'baseScreen.dart';

class UnrecognizedUserScreen extends StatefulWidget {
  const UnrecognizedUserScreen({super.key});

  @override
  State<UnrecognizedUserScreen> createState() => _UnrecognizedUserScreenState();
}

class _UnrecognizedUserScreenState extends State<UnrecognizedUserScreen> {
  @override
  Widget build(BuildContext context) {
    return const BaseScreen(text: "User not recognized", color: Color.fromRGBO(255, 0, 0, 1), icon: Icons.error, secondColor: Colors.white);
  }
}