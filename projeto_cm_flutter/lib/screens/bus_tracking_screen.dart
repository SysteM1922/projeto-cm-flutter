import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:geolocator/geolocator.dart';
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

  final MapController _mapController = MapController();
  double _currentZoom = 14.0;

  StreamSubscription<ServiceStatus>? _locationServiceStatusStream;
  bool _locationServiceEnabled = false;

  @override
  void initState() {
    super.initState();

    _checkConnection();
    _requestLocationPermission();
    _listenToLocationServiceStatus();
  }

  @override
  void dispose() {
    _locationServiceStatusStream?.cancel();
    super.dispose();
  }

  void _checkConnection() async {
    bool result = await InternetConnectionChecker().hasConnection;

    if (!result) {
      setState(() {
        _wifiIcon = Icon(Icons.wifi_off, color: Colors.red);
      });
      return;
    }

    setState(() {
      _wifiIcon = Icon(Icons.wifi, color: Color.fromRGBO(48, 170, 44, 1));
    });
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission;

    // Check if location services are enabled
    _locationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!_locationServiceEnabled) {
      _showLocationServiceDisabledDialog();
      setState(() {
        _gpsIcon = Icon(Icons.gps_off,
            color: Color.fromRGBO(129, 129, 129, 1), size: 35);
      });
      return;
    }

    // Request permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {

        return;
      }
    }

    // Permissions granted, get current location
    Position position = await Geolocator.getCurrentPosition();

    // Recenter the map to the user's current location
    _mapController.move(
        LatLng(position.latitude, position.longitude), _currentZoom);

    setState(() { // change the GPS icon to blue
      _gpsIcon = Icon(Icons.gps_fixed,
          color: Color.fromRGBO(0, 153, 255, 1), size: 35);
    });
  }

  void _listenToLocationServiceStatus() { 
    _locationServiceStatusStream = Geolocator.getServiceStatusStream().listen(
      (ServiceStatus status) {
        if (status == ServiceStatus.disabled) {
          _showLocationServiceDisabledDialog();
          setState(() {
            _gpsIcon = Icon(Icons.gps_off,
                color: Color.fromRGBO(129, 129, 129, 1), size: 35);
          });
        } else if (status == ServiceStatus.enabled) {
          _requestLocationPermission();
        }
      },
    );
  }

  void _showLocationServiceDisabledDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Services Disabled'),
          content:
              Text('Please enable location services to use this feature.'),
          actions: [
            TextButton(
              child: Text('Enable'),
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openLocationSettings();
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  void _recenterMap() async {
    // Recenter the map to the user's current location
    try {
      Position position = await Geolocator.getCurrentPosition();

      _mapController.move(
          LatLng(position.latitude, position.longitude), _currentZoom);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get current location.'),
        ),
      );
    }
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
              initialZoom: _currentZoom,
              minZoom: 7.0,
              maxZoom: 18.0,
              cameraConstraint: CameraConstraint.contain(
                  bounds: LatLngBounds(
                      LatLng(42.29301588859787, -6.047089196299635),
                      LatLng(36.660350971821785, -10.027199015120786))),
              keepAlive: true,
              onMapEvent: (MapEvent event) {
                if (event is MapEventMoveEnd) {
                  setState(() {
                    // something
                  });
                }
              },
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
                            content: Text(
                                'No connection to fetch tiles. Showing cached tiles instead.'),
                          ),
                        );
                        _checkConnection();
                      }
                    },
                  ),
                ),
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.projeto_cm_flutter',
              ),
              // Add a marker for the user's location
              if (_locationServiceEnabled)
                FutureBuilder<Position>(
                  future: Geolocator.getCurrentPosition(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      Position position = snapshot.data!;
                      return MarkerLayer(
                        markers: [
                          Marker(
                            point:
                                LatLng(position.latitude, position.longitude),
                            width: 30,
                            height: 30,
                            child: Icon(Icons.my_location,
                                color: Colors.blue, size: 30),
                          ),
                        ],
                      );
                    } else {
                      return Container();
                    }
                  },
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
              onPressed: () {
                // Optionally, you can toggle GPS status here or handle other actions
                _requestLocationPermission();
              },
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
