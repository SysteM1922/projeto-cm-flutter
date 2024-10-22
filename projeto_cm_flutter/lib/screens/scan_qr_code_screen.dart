import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:projeto_cm_flutter/screens/result_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ScanQRCodeScreen extends StatefulWidget {
  const ScanQRCodeScreen({super.key});

  @override
  State<ScanQRCodeScreen> createState() => _ScanQRCodeScreenState();
}

class _ScanQRCodeScreenState extends State<ScanQRCodeScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _screenOpened = false;
  bool isTorchOn = false;
  bool _isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    dotenv.load();
  }

  void _foundBarcode(BarcodeCapture barcodeCapture) {
    final List<Barcode> barcodes = barcodeCapture.barcodes;
    if (!_screenOpened && barcodes.isNotEmpty) {
      final String code = barcodes.first.rawValue ?? '---';
      debugPrint('Barcode found! $code');
      final String apiUrl = dotenv.env['API_URL'] ?? '';

      // Validate if the scanned code starts with the API_URL
      if (code.startsWith(apiUrl)) {
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
      } else if (!_isDialogOpen) {
        // Show error if the scanned code doesn't match the API_URL and no dialog is open
        _showInvalidUrlDialog();
      }
    }
  }

  void _screenWasClosed() {
    _screenOpened = false;
  }

  void _showInvalidUrlDialog() {
    _isDialogOpen = true; 
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Invalid QR Code"),
          content: const Text(
              "The scanned QR code is invalid. Please scan a valid URL."),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                _isDialogOpen = false;
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
