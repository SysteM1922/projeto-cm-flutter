import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_nfc_hce/flutter_nfc_hce.dart';
import 'package:flutter_nfc_hce/flutter_nfc_hce_platform_interface.dart';

class NFCScreen extends StatefulWidget {
  const NFCScreen({super.key});

  @override
  State<NFCScreen> createState() => _NFCScreenState();
}

class _NFCScreenState extends State<NFCScreen> with WidgetsBindingObserver {
  final FlutterNfcHce _flutterNfcHcePlugin = FlutterNfcHce();

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
    //getPlatformVersion
    var platformVersion = await _flutterNfcHcePlugin.getPlatformVersion();

    if (platformVersion == null) {
      _showDialog('NFC is not supported on this device.');
      return;
    }

    //isNfcHceSupported
    bool? isNfcHceSupported = await _flutterNfcHcePlugin.isNfcHceSupported();

    if (!isNfcHceSupported) {
      _showDialog('NFC HCE is not supported on this device.');
      return;
    }

    //isNfcEnabled
    bool? isNfcEnabled = await _flutterNfcHcePlugin.isNfcEnabled();

    if (!isNfcEnabled) {
      _showDialog('NFC is not enabled on this device.');
      return;
    }
  }

  Future<String?> startNfcHce(
    String content, {
    String mimeType = 'text/plain',
    bool persistMessage = true,
  }) {
    return FlutterNfcHcePlatform.instance.startNfcHce(
      content,
      mimeType,
      persistMessage,
    );
  }

  void _emulateNfcCard() async {
    //nfc content
    var id = 'guilherme_antunes';

    await startNfcHce(id);
  }

  void _stopNfcHce() async {
    await FlutterNfcHcePlatform.instance.stopNfcHce();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _checkNFC();

    _emulateNfcCard();
  }

  @override
  void dispose() {
    _stopNfcHce();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _stopNfcHce();
    } else if (state == AppLifecycleState.resumed) {
      _emulateNfcCard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Validation'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Flexible(
              child: Container(
                  margin: EdgeInsets.only(
                      top: 20.0, left: 20.0, right: 20.0, bottom: 20.0),
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(1),
                        spreadRadius: 0,
                        blurRadius: 5,
                        offset:
                            const Offset(10, 10), // changes position of shadow
                      ),
                    ],
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30.0),
                    child: Image.asset(
                      'assets/images/card.png',
                    ),
                  ))),
          Container(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              textAlign: TextAlign.center,
              'Please tap your card on the NFC reader.',
              style: TextStyle(fontSize: 24.0),
            ),
          ),
        ],
      ),
    );
  }
}
