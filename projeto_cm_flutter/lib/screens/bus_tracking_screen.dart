import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class BusTrackingScreen extends StatefulWidget {
  const BusTrackingScreen({super.key});

  @override
  State<BusTrackingScreen> createState() => _BusTrackingScreenState();
}

class _BusTrackingScreenState extends State<BusTrackingScreen> {
  Icon _wifiIcon = Icon(Icons.wifi, color: Color.fromRGBO(48, 170, 44, 1));
  Icon _gpsIcon = Icon(Icons.gps_off, color: Colors.red, size: 35);

  final MapController _mapController = MapController();

  LatLng center = LatLng(40.63672, -8.65049);
  AlignOnUpdate _alignOnUpdate = AlignOnUpdate.never;

  int _currentOption = 1;
  bool _gpsOn = false;

  bool _internetModal = false;

  StreamSubscription<ServiceStatus>? _locationServiceStatusStream;
  StreamSubscription<List<ConnectivityResult>>? _connectionServiceStatusStream;

  @override
  void initState() {
    super.initState();

    _listenToConnectionServiceStatus();
    _requestLocationPermission();
    _listenToLocationServiceStatus();
  }

  @override
  void dispose() {
    _locationServiceStatusStream?.cancel();
    _connectionServiceStatusStream?.cancel();
    super.dispose();
  }

  void _showConnectionDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Internet Conection Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Ok', style: TextStyle(color: Colors.blue[800])),
            ),
          ],
        );
      },
    );
  }

  void _showLocationDialog(message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await Geolocator.openLocationSettings();
              },
              child: Text('Enable', style: TextStyle(color: Colors.blue[800])),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('No', style: TextStyle(color: Colors.blue[800])),
            ),
          ],
        );
      },
    );
  }

  void _toOption0() {
    _gpsIcon = Icon(Icons.gps_off, color: Colors.red, size: 35);
    _currentOption = 0;
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _toOption1() {
    _gpsIcon = Icon(Icons.gps_not_fixed, color: Color.fromRGBO(129, 129, 129, 1), size: 35);
    _currentOption = 1;
    _alignOnUpdate = AlignOnUpdate.never;
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _toOption2(Position position) {
    _mapController.move(LatLng(position.latitude, position.longitude), _mapController.camera.zoom);
    _gpsIcon = Icon(Icons.gps_fixed, color: Color.fromRGBO(0, 153, 255, 1), size: 35);
    _currentOption = 2;
    _alignOnUpdate = AlignOnUpdate.never;
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _toOption3(Position position) {
    _mapController.moveAndRotate(LatLng(position.latitude, position.longitude), 17.0, _mapController.camera.rotation);
    _gpsIcon = Icon(Icons.explore, color: Color.fromRGBO(0, 153, 255, 1), size: 35);
    _currentOption = 3;
    _alignOnUpdate = AlignOnUpdate.always;
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _gpsOn = false;
        _toOption0();
      } else if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(locationSettings: LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 10));
        center = LatLng(position.latitude, position.longitude);
        _gpsOn = true;
        _toOption2(position);
      } else if (permission == LocationPermission.deniedForever) {
        _gpsOn = false;
        _showLocationDialog("Please enable location services to use this feature.");
      }
    } catch (e) {
      _gpsOn = false;
      _toOption0();
    }
  }

  void _listenToLocationServiceStatus() async {
    _locationServiceStatusStream = Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      if (status == ServiceStatus.disabled) {
        if (_currentOption != 0) {
          _toOption0();
        }
      } else if (status == ServiceStatus.enabled) {
        if (_currentOption == 0) {
          _gpsOn = true;
          _toOption1();
        }
      }
      // Está a rebentar aqui
    });
  }

  void _listenToConnectionServiceStatus() async {
    _connectionServiceStatusStream = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      if (!result.contains(ConnectivityResult.wifi) &&
          !result.contains(ConnectivityResult.mobile) &&
          !result.contains(ConnectivityResult.ethernet) &&
          !result.contains(ConnectivityResult.vpn)) {
        if (!_internetModal) {
          _showConnectionDialog("You are offline. Using offline map data. When you are online the map will update.");
          _internetModal = true;
        }
        if (!mounted) {
          return;
        }
        setState(() {
          _wifiIcon = Icon(Icons.wifi_off, color: Colors.red);
        });
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _internetModal = false;
        _wifiIcon = Icon(Icons.wifi, color: Color.fromRGBO(48, 170, 44, 1));
      });
    });
  }

  void _changeLocationOption() async {
    if (_gpsOn) {
      try {
        Position position = await Geolocator.getCurrentPosition(
            locationSettings: LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 10, timeLimit: Duration(seconds: 3)));
        if (_currentOption == 1) {
          _toOption2(position);
        } else if (_currentOption == 2) {
          _toOption3(position);
        } else if (_currentOption == 3) {
          _toOption2(position);
        }
      } catch (e) {
        return;
      }
    } else {
      _requestLocationPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
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
              maxZoom: 18.0,
              cameraConstraint: CameraConstraint.contain(
                  bounds: LatLngBounds(LatLng(42.29301588859787, -6.047089196299635), LatLng(36.660350971821785, -10.027199015120786))),
              keepAlive: true,
              onMapEvent: (MapEvent event) {
                if (event is MapEventMoveStart) {
                  if (_currentOption > 1) {
                    _toOption1();
                  }
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
                  ),
                ),
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.projeto_cm_flutter',
              ),
              if (_gpsOn)
                CurrentLocationLayer(
                  alignPositionOnUpdate: _alignOnUpdate,
                  alignDirectionOnUpdate: _alignOnUpdate,
                ),
            ],
          ),
          Positioned(
            top: 10,
            right: 10,
            child: ElevatedButton(
              onPressed: () => {},
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
                _changeLocationOption();
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
