import 'package:flutter/material.dart';
import 'package:nfc_reader/messageScreens/baseScreen.dart';

class NoConnectionScreen extends StatefulWidget {
  const NoConnectionScreen({super.key});

  @override
  State<NoConnectionScreen> createState() => _NoConnectionScreenState();
}

class _NoConnectionScreenState extends State<NoConnectionScreen> {
  @override
  Widget build(BuildContext context) {
    return const BaseScreen(text: "No Internet Connection", color: Color.fromRGBO(159, 57, 218, 1), icon: Icons.wifi_off, secondColor: Colors.white);
  }
}