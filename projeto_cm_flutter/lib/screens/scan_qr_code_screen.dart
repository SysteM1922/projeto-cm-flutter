import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:projeto_cm_flutter/screens/schedule_screen.dart';
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

  final DatabaseService dbService = DatabaseService.getInstance();

  @override
  void initState() {
    super.initState();

    _checkCameraPermissions();
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Camera Permissions'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _requestCameraPermissions();
              },
              child: Text('Enable', style: TextStyle(color: Colors.blue[800])),
            ),
            TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('No', style: TextStyle(color: Colors.blue[800]))),
          ],
        );
      },
    );
  }

  void _requestCameraPermissions() async {
    await openAppSettings();
  }

  void _checkCameraPermissions() async {
    final PermissionStatus status = await Permission.camera.status;
    if (status.isPermanentlyDenied) {
      _showDialog('Please enable camera permissions to use this feature.');
    }
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
            builder: (context) => ScheduleScreen(
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
          content: const Text(
              "The scanned QR code is invalid. Please scan a valid stop QR code."),
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
          content: const Text(
              "The stop ID scanned does not exist in the local database."),
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
              controller: cameraController,
              onDetect: _foundBarcode,
              errorBuilder: (p0, p1, p2) {
                return GestureDetector(
                  onTap: () {
                    _checkCameraPermissions();
                    cameraController.start();
                  },
                  child: ColoredBox(
                    color: Colors.black,
                    child:
                        Center(child: Icon(Icons.error, color: Colors.white)),
                  ),
                );
              }),
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
