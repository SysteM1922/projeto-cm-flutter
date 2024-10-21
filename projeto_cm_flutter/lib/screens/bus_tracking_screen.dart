import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:latlong2/latlong.dart';

class BusTrackingScreen extends StatefulWidget {
  const BusTrackingScreen({super.key});

  @override
  State<BusTrackingScreen> createState() => _BusTrackingScreenState();
}

class _BusTrackingScreenState extends State<BusTrackingScreen> {
  Icon _wifiIcon = Icon(Icons.wifi, color: Color.fromRGBO(48, 170, 44, 1));
  Icon _gpsIcon =
      Icon(Icons.gps_fixed, color: Color.fromRGBO(0, 153, 255, 1), size: 35);

  MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();

    _checkConnection();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _checkGPS() async {
    // change for gps
    bool result = await InternetConnectionChecker().hasConnection;

    setState(() {
      if (!result) {
        _gpsIcon = Icon(Icons.gps_off,
            color: Color.fromRGBO(129, 129, 129, 1), size: 35);
      } else {
        _gpsIcon = Icon(Icons.gps_fixed,
            color: Color.fromRGBO(0, 153, 255, 1), size: 35);
      }
    });
  }

  void _checkConnection() async {
    bool result = await InternetConnectionChecker().hasConnection;

    setState(() {
      if (!result) {
        _wifiIcon = Icon(Icons.wifi_off, color: Color.fromRGBO(212, 53, 53, 1));
      } else {
        _wifiIcon = Icon(Icons.wifi, color: Color.fromRGBO(48, 170, 44, 1));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final LatLng center = LatLng(40.63672, -8.65049);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Tracking'),
        backgroundColor: Colors.blue[800],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 14.0,
              minZoom: 7.0,
              cameraConstraint: CameraConstraint.contain(
                  bounds: LatLngBounds(
                      LatLng(42.29301588859787, -6.047089196299635),
                      LatLng(36.660350971821785, -10.027199015120786))),
              keepAlive: true,
            ),
            children: [
              TileLayer(
                tileProvider: FMTCStore('busMap').getTileProvider(
                    settings: FMTCTileProviderSettings(
                  behavior: CacheBehavior.cacheFirst,
                  fallbackToAlternativeStore: true,
                  cachedValidDuration: const Duration(days: 30),
                  maxStoreLength: 1000,
                  errorHandler: (e) {
                    if (e.type ==
                        FMTCBrowsingErrorType.noConnectionDuringFetch) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('No connection to fetch tiles. '
                                'Showing cached tiles instead.')),
                      );
                      _checkConnection();
                    }
                  },
                )),
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                panBuffer: 0,
                userAgentPackageName: 'com.example.projeto_cm_flutter',
              ),
            ],
          ),
          Positioned(
            top: 10,
            right: 10,
            child: ElevatedButton(
              onPressed: _checkConnection,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: EdgeInsets.all(20),
              ),
              child: _wifiIcon,
            ),
          ),
          Positioned(
            bottom: 20,
            right: 10,
            child: ElevatedButton(
              onPressed: _checkGPS,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: EdgeInsets.all(15),
              ),
              child: _gpsIcon,
            ),
          ),
        ],
      ),
    );
  }
}
