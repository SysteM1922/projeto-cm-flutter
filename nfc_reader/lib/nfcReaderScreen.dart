import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

class NFCReaderScreen extends StatefulWidget {
  const NFCReaderScreen({super.key});

  @override
  State<NFCReaderScreen> createState() => _NFCReaderScreenState();
}

class _NFCReaderScreenState extends State<NFCReaderScreen> {
  String _ndefContent = 'Waiting for NFC card...';

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
    } else {
      _readNFC();
    }
  }

  void _readNFC() async {
    NfcManager.instance.startSession(
      onError: (error) async {
        log('-------------->error: $error');
        _showDialog('Error reading NFC card: $error');
      },
      onDiscovered: (NfcTag tag) async {
        var ndef = Ndef.from(tag);
        if (ndef == null) {
          log('Tag is not compatible with NDEF');
          return;
        }

        var record = tag.data['ndef']['cachedMessage']['records'][0];

        var payload = Uint8List.fromList(record['payload']);

        var error = [
          2,
          101,
          110,
          67,
          105,
          97,
          111,
          44,
          32,
          99,
          111,
          109,
          101,
          32,
          118,
          97,
          63
        ]; // \^BenCiao, come v<…>

        if (payload.toString() != error.toString()) {
          //payload list index from 1 to list's length
          _ndefContent = utf8.decode(Uint8List.fromList(payload.sublist(3)));
        } else {
          log('Error reading NFC card');
        }

        setState(() {
          _ndefContent =
              'Payload: $_ndefContent';
        });
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
            Container(
              margin: const EdgeInsets.only(bottom: 20.0),
              child: Text(
                _ndefContent,
                style: const TextStyle(fontSize: 10.0),
              ),
            ),
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
