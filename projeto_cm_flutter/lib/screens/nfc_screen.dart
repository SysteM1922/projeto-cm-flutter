import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

class NFCScreen extends StatefulWidget {
  const NFCScreen({super.key});

  @override
  _NFCScreenState createState() => _NFCScreenState();
}

class _NFCScreenState extends State<NFCScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFC Validation'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.nfc,
              size: 100.0,
            ),
            const SizedBox(height: 20.0),
            const Text(
              'NFC Validation',
              style: TextStyle(fontSize: 24.0),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                // Navigate to NFC Validation screen (to be implemented)
              },
              child: const Text('Scan NFC Card'),
            ),
          ],
        ),
      ),
    );
  }
}