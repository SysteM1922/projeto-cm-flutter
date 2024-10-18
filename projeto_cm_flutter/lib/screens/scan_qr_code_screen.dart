import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:projeto_cm_flutter/screens/result_screen.dart';

class ScanQRCodeScreen extends StatefulWidget {
  const ScanQRCodeScreen({Key? key}) : super(key: key);

  @override
  State<ScanQRCodeScreen> createState() => _ScanQRCodeScreenState();
}

class _ScanQRCodeScreenState extends State<ScanQRCodeScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _screenOpened = false;
  bool isTorchOn = false;

  void _foundBarcode(BarcodeCapture barcodeCapture) {
    final List<Barcode> barcodes = barcodeCapture.barcodes;
    if (!_screenOpened && barcodes.isNotEmpty) {
      final String code = barcodes.first.rawValue ?? '---';
      debugPrint('Barcode found! $code');
      _screenOpened = true;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            code: code,
            screenClosed: _screenWasClosed,
          ),
        ),
      );
    }
  }

  void _screenWasClosed() {
    _screenOpened = false;
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan QR Code"),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            color: Colors.white,
            icon: Icon(isTorchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              cameraController.toggleTorch();
              setState(() {
                isTorchOn = !isTorchOn;
              });
            },
          ),
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.cameraswitch),
            onPressed: () {
              cameraController.switchCamera();
            },
          ),
        ],
      ),
      body: MobileScanner(
        controller: cameraController,
        onDetect: _foundBarcode,
      ),
    );
  }
}
