import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

class NFCReaderScreen extends StatefulWidget {
  const NFCReaderScreen({super.key});

  @override
  State<NFCReaderScreen> createState() => _NFCReaderScreenState();
}

class _NFCReaderScreenState extends State<NFCReaderScreen> {
  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('NFC Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _checkNFC();
              },
              child: const Text('Ok'),
            ),
          ],
        );
      },
    );
  }

  void _checkNFC() async {
    bool isNFCEnabled = await NfcManager.instance.isAvailable();

    if (!isNFCEnabled) {
      _showDialog(
          'NFC functionality is not enabled on this device.\nPlease enable NFC and try again.');
    }
    else {
      _readNFC();
    }
  }

  void _readNFC() async {
    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        log('Tag discovered: ${tag.data}');
      },
    );
  }

  @override
  void initState() {
    super.initState();

    _checkNFC();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.contactless_rounded,
              size: 100.0,
            ),
            Container(
              margin: const EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0),
              child: const Text(
                textAlign: TextAlign.center,
                'Please tap your card on the back of this device to validate.',
                style: TextStyle(fontSize: 24.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
