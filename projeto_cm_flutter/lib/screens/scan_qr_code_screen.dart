import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:projeto_cm_flutter/screens/result_screen.dart';

import 'package:projeto_cm_flutter/isar/models.dart' as models;
import 'package:projeto_cm_flutter/services/database_service.dart'; 

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

  final DatabaseService dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
  }

  void _foundBarcode(BarcodeCapture barcodeCapture) async {
    final List<Barcode> barcodes = barcodeCapture.barcodes;
    if (!_screenOpened && barcodes.isNotEmpty) {
      final String code = barcodes.first.rawValue ?? '---';
      debugPrint('Barcode found! $code');

      // Assume the QR code contains the stop_id
      final String stopId = code.trim();

      if (stopId.isEmpty) {
        if (!_isDialogOpen) {
          _showInvalidStopIdDialog();
        }
        return;
      }

      // check if its a URL
      if (stopId.startsWith('http')) {
        if (!_isDialogOpen) {
          _showInvalidStopIdDialog();
        }
        return;
      }

      // Query the database for the stop with the given stopId
      final models.Stop? stop = await dbService.getStopById(stopId);

      if (stop != null) {
        _screenOpened = true;
        // Pass the stop data to the ResultScreen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              stop: stop,
              screenClosed: _screenWasClosed,
            ),
          ),
        );
      } else {
        if (!_isDialogOpen) {
          _showStopNotFoundDialog();
        }
      }
    }
  }

  void _screenWasClosed() {
    _screenOpened = false;
  }

  void _showInvalidStopIdDialog() {
    _isDialogOpen = true;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Invalid QR Code"),
          content:
              const Text("The scanned QR code is invalid. Please scan a valid stop QR code."),
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

  void _showStopNotFoundDialog() {
    _isDialogOpen = true;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Stop Not Found"),
          content: const Text("The stop ID scanned does not exist in the local database."),
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
    // DO NOT CLOSE ISAR HERE
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _foundBarcode,
          ),
          Positioned(
            top: 40,
            right: 60,
            child: IconButton(
              color: Colors.white,
              icon: Icon(
                isTorchOn ? Icons.flash_on : Icons.flash_off,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    offset: Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              onPressed: () {
                cameraController.toggleTorch();
                if (!mounted) {
                  return;
                }
                setState(() {
                  isTorchOn = !isTorchOn;
                });
              },
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              color: Colors.white,
              icon: const Icon(Icons.cameraswitch, shadows: [
                Shadow(
                  color: Colors.black,
                  offset: Offset(1, 1),
                  blurRadius: 2,
                ),
              ]),
              onPressed: () {
                cameraController.switchCamera();
              },
            ),
          )
        ],
      ),
    );
  }
}
