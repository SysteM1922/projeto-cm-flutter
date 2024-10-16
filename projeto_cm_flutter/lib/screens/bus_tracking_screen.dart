// bus_tracking_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class BusTrackingScreen extends StatefulWidget {
  const BusTrackingScreen({super.key});

  @override
  State<BusTrackingScreen> createState() => _BusTrackingScreenState();
}

class _BusTrackingScreenState extends State<BusTrackingScreen> { 

  @override
  Widget build(BuildContext context) {
    final LatLng center = LatLng(double.parse('38.736946'), double.parse('-9.142685'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-time Bus Tracking'),
        backgroundColor: Colors.blue[800],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: center,
          initialZoom: 15.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            panBuffer: 0,
            userAgentPackageName: 'com.example.projeto_cm_flutter',
          ),
        ],
      ),
    );
  }
}
