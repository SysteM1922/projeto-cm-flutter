import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nfc_host_card_emulation/nfc_host_card_emulation.dart';

class NFCScreen extends StatefulWidget {
  const NFCScreen({super.key});

  @override
  State<NFCScreen> createState() => _NFCScreenState();
}

class _NFCScreenState extends State<NFCScreen> {



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
            TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Cancel')),
          ],
        );
      },
    );
  }

  void _checkNFC() async {
    final nfcState = await NfcHce.checkDeviceNfcState();

    if (nfcState != NfcState.enabled) {
      _showDialog(
          'NFC functionality is not enabled on this device.\nPlease enable NFC and try again.');
    } else {
      await NfcHce.init(
        // AID that match at least one aid-filter in apduservice.xml.
        aid: Uint8List.fromList([0xA0, 0x00, 0xDA, 0xDA, 0xDA, 0xDA, 0xDA]),

        // next parameter determines whether APDU responses from the ports
        // on which the connection occurred will be deleted.
        // If `true`, responses will be deleted, otherwise won't.
        permanentApduResponses: true,

        // next parameter determines whether APDU commands received on ports
        // to which there are no responses will be added to the stream.
        // If `true`, command won't be added, otherwise will.
        listenOnlyConfiguredPorts: false,
      );
    }
  }

  @override
  void initState() {
    super.initState();

    _checkNFC();

    NfcHce.stream.listen((command) {
      
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Validation'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.contactless_rounded,
              size: 100.0,
            ),
            Container(
              margin: EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0),
              child: Text(
                textAlign: TextAlign.center,
                'Please tap your card on the NFC reader.',
                style: TextStyle(fontSize: 24.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
