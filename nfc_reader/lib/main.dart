import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nfc_reader/nfcReaderScreen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.white,
    ));

    return const MaterialApp(
      home: NFCReaderScreen(),
    );
  }
}