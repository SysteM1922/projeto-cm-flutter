import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nfc_manager/nfc_manager.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import 'package:nfc_reader/messageScreens/apiErrorScreen.dart';
import 'package:nfc_reader/messageScreens/noConnectionScreen.dart';
import 'package:nfc_reader/messageScreens/unrecognizedCardScreen.dart';
import 'package:nfc_reader/messageScreens/unrecognizedUserScreen.dart';
import 'package:nfc_reader/messageScreens/successScreen.dart';

class NFCReaderScreen extends StatefulWidget {
  const NFCReaderScreen({super.key});

  @override
  State<NFCReaderScreen> createState() => _NFCReaderScreenState();
}

class _NFCReaderScreenState extends State<NFCReaderScreen>
    with WidgetsBindingObserver {
  String _apiUrl = '';
  String _busId = '';

  Stream<bool> _nfcStatus = Stream<bool>.empty();

  bool _modalOpen = false;

  @override
  void initState() {
    super.initState();

    _apiUrl = dotenv.env['API_URL']!;
    _busId = dotenv.env['BUS_ID']!;

    WidgetsBinding.instance.addObserver(this);

    _checkNFC();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _showDialog(String message) {
    if (_modalOpen) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _modalOpen = true;
      setState(() {});
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
                  _modalOpen = false;
                  setState(() {});
                  _checkNFC();
                },
                child: const Text('Ok'),
              ),
            ],
          );
        },
      );
    });
  }

  void _checkNFC() async {
    _nfcStatus =
        Stream.periodic(const Duration(seconds: 1)).asyncMap((_) async {
      bool? isNfcEnabled = await NfcManager.instance.isAvailable();

      if (!isNfcEnabled) {
        return false;
      }

      return true;
    });

    if (!mounted) return;
    setState(() {});
  }

  void _alertPage(StatefulWidget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
    });
  }

  void _readNFC() async {
    String ndefContent = '';

    NfcManager.instance.startSession(
      onError: (error) async {
        _showDialog('Error reading NFC card: $error');
      },
      onDiscovered: (NfcTag tag) async {
        bool result = await InternetConnectionChecker().hasConnection;

        if (!result) {
          _alertPage(const NoConnectionScreen());
          return;
        }

        var ndef = Ndef.from(tag);
        if (ndef == null) {
          _showDialog('Error reading NFC card: NDEF is null');
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
        ];

        if (payload.toString() != error.toString()) {
          //payload list index from 1 to list's length
          ndefContent = utf8.decode(Uint8List.fromList(payload.sublist(3)));

          if (ndefContent == '') {
            _alertPage(const UnrecognizedCardScreen());
            return;
          }
        } else {
          _alertPage(const UnrecognizedCardScreen());
          return;
        }

        http.Response response = await http.post(
          Uri.parse('$_apiUrl/travel/register'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, String>{
            'bus_id': _busId,
            'user_id': ndefContent,
          }),
        );

        if (response.statusCode == 404 || response.statusCode == 422) {
          _alertPage(const UnrecognizedUserScreen());
        } else if (response.statusCode == 200) {
          String user = jsonDecode(response.body)['user_name'];
          _alertPage(SuccessScreen(extraText: user));
        } else {
          _alertPage(const APIErrorScreen());
        }
      },
    );
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
              child: const Text(
                'Waiting for NFC card...',
                style: TextStyle(fontSize: 10.0),
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
            StreamBuilder<bool>(
                stream: _nfcStatus,
                builder: (context, snapshot) {
                  if (snapshot.data == false) {
                    if (_modalOpen) {
                      return const SizedBox.shrink(); // Return an empty widget
                    }
                    _showDialog(
                        'NFC is not enabled on this device. Please enable it.');
                  } else if (snapshot.data == true) {
                    _readNFC();
                  }
                  return const SizedBox.shrink(); // Return an empty widget
                }),
          ],
        ),
      ),
    );
  }
}
