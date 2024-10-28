import 'package:flutter/material.dart';
import 'package:flutter_nfc_hce/flutter_nfc_hce.dart';
import 'package:flutter_nfc_hce/flutter_nfc_hce_platform_interface.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:projeto_cm_flutter/state/app_state.dart';
import 'package:provider/provider.dart';

class NFCScreen extends StatefulWidget {
  const NFCScreen({super.key});

  @override
  State<NFCScreen> createState() => _NFCScreenState();
}

class _NFCScreenState extends State<NFCScreen> with WidgetsBindingObserver {
  final FlutterNfcHce _flutterNfcHcePlugin = FlutterNfcHce();
  final _storage = FlutterSecureStorage();

  bool _modalOpen = false;

  Stream<bool> _nfcStatus = Stream<bool>.empty();

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
    WidgetsBinding.instance.removeObserver(this);

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
                },
                child: Text('Ok', style: TextStyle(color: Colors.blue[800])),
              ),
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final appState = Provider.of<AppState>(context, listen: false);
                      appState.setSelectedTab(0);
                    });
                  },
                  child: Text('Cancel', style: TextStyle(color: Colors.blue[800]))),
            ],
          );
        },
      );
    });
  }

  void _checkNFC() async {
    //getPlatformVersion
    var platformVersion = await _flutterNfcHcePlugin.getPlatformVersion();

    if (platformVersion == null) {
      _showDialog('NFC is not supported on this device.');
      return;
    }

    _nfcStatus = Stream.periodic(Duration(seconds: 1)).asyncMap((_) async {
      bool? isNfcEnabled = await _flutterNfcHcePlugin.isNfcEnabled();

      if (!isNfcEnabled) {
        return false;
      }

      return true;
    });

    if (!mounted) return;
    setState(() {});
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
    var id = await _storage.read(key: 'user_id');

    await startNfcHce(id ?? '0000000000000000');
  }

  void _stopNfcHce() async {
    await FlutterNfcHcePlatform.instance.stopNfcHce();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 60.0),
            child: Text(
              textAlign: TextAlign.center,
              'Please tap your card on the NFC reader.',
              style: TextStyle(fontSize: 24.0),
            ),
          ),
          Flexible(
              child: Container(
                  margin: EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0, bottom: 20.0),
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(1),
                        spreadRadius: 0,
                        blurRadius: 5,
                        offset: const Offset(10, 10), // changes position of shadow
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
          StreamBuilder<bool>(
              stream: _nfcStatus,
              builder: (context, snapshot) {
                if (snapshot.data == false) {
                  _showDialog('NFC is not enabled on this device. Please enable it.');
                }
                return SizedBox.shrink(); // Return an empty widget
              }),
        ],
      ),
    );
  }
}
