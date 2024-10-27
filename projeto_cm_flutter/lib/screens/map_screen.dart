import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart' as permission;
import 'package:projeto_cm_flutter/isar/models.dart' as models;
import 'package:projeto_cm_flutter/screens/bus_screen.dart';
import 'package:projeto_cm_flutter/screens/bus_tracker.dart';
import 'package:projeto_cm_flutter/screens/schedule_screen.dart';
import 'package:projeto_cm_flutter/services/database_service.dart'; // DatabaseService to get the singleton instance

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.stopId});
  final String? stopId;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final DatabaseService dbService = DatabaseService.getInstance();

  Icon _gpsIcon = Icon(Icons.gps_off, color: Colors.red, size: 35);

  late final AnimatedMapController _mapController =
      AnimatedMapController(vsync: this);
  LatLng _center = LatLng(40.63672, -8.65049);
  AlignOnUpdate _alignOnUpdate = AlignOnUpdate.never;

  int _currentOption = 1;
  bool _gpsOn = false;
  bool _mapInfo = false;
  bool _moving = false;
  late Widget _info;
  var _selected;

  StreamSubscription<ServiceStatus>? _locationServiceStatusStream;

  static List<Marker> _markersList = [];

  @override
  void initState() {
    super.initState();

    _getMarkers(widget.stopId);

    _requestLocationPermission();
    _listenToLocationServiceStatus();
  }

  @override
  void dispose() {
    _locationServiceStatusStream?.cancel();
    super.dispose();
  }

  void _markerTapped(models.Stop stop) async {
    _info = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.touch_app,
          size: 30,
          color: Colors.transparent,
        ),
        Flexible(
          flex: 2,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              utf8.decode(stop.stopName!.codeUnits),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ),
        Icon(
          Icons.touch_app,
          size: 30,
          color: Colors.green,
        ),
      ],
    );
    _moving = true;
    _mapInfo = true;
    _selected = stop;
    setState(() {});

    _mapController.centerOnPoint(LatLng(stop.latitude!, stop.longitude!));
  }

  void _busTapped(
      LatLng position, Itinerarie itinerary, int updateInterval) async {
    _info = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.touch_app,
          size: 30,
          color: Colors.transparent,
        ),
        Flexible(
          flex: 2,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              utf8.decode(itinerary.name.codeUnits),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Icon(
          Icons.touch_app,
          size: 30,
          color: Colors.green,
        ),
      ],
    );

    _moving = true;
    _mapInfo = true;
    _selected = itinerary.id;
    setState(() {});

    _mapController.centerOnPoint(position);
    Future.delayed(Duration(milliseconds: 600), () {
      _moving = false;
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _getMarkers(String? centerStopId) async {
    List<models.Stop> stops = await dbService.getAllStops();
    models.Stop? savedStop;

    for (var stop in stops) {
      if (stop.latitude == null || stop.longitude == null) {
        continue;
      }
      if (centerStopId != null && stop.serverId == centerStopId) {
        savedStop = stop;
      }
      _markersList.add(Marker(
        width: 40.0,
        height: 40.0,
        point: LatLng(stop.latitude!, stop.longitude!),
        child: GestureDetector(
          onTap: () {
            _markerTapped(stop);
          },
          child: Icon(
            Icons.location_on,
            color: Colors.red,
            size: 40.0,
            shadows: [
              Shadow(
                color: Colors.black,
                offset: Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        alignment: Alignment(0, -1.0),
        rotate: true,
      ));
    }
    if (!mounted) {
      return;
    }
    setState(() {});
    if (savedStop != null) _markerTapped(savedStop);
  }

  void _showLocationDialog(message) {
    setState(() {});
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
                _requestLocationPermission();
                setState(() {});
              },
              child: Text('Enable', style: TextStyle(color: Colors.blue[800])),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {});
              },
              child: Text('No', style: TextStyle(color: Colors.blue[800])),
            ),
          ],
        );
      },
    );
  }

  void _toOption0() {
    _alignOnUpdate = AlignOnUpdate.never;
    _gpsOn = false;
    _gpsIcon = Icon(Icons.gps_off, color: Colors.red, size: 35);
    _currentOption = 0;
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _toOption1() {
    _alignOnUpdate = AlignOnUpdate.never;
    _gpsOn = true;
    _gpsIcon = Icon(Icons.gps_not_fixed,
        color: Color.fromRGBO(129, 129, 129, 1), size: 35);
    _currentOption = 1;
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _toOption2([Position? position]) async {
    _alignOnUpdate = AlignOnUpdate.never;
    _gpsOn = true;
    _gpsIcon =
        Icon(Icons.gps_fixed, color: Color.fromRGBO(0, 153, 255, 1), size: 35);
    _currentOption = 2;
    if (!mounted) {
      return;
    }
    setState(() {});
    position ??= await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
            accuracy: LocationAccuracy.best, distanceFilter: 10));
    _mapController.centerOnPoint(LatLng(position.latitude, position.longitude));
  }

  void _toOption3() async {
    _alignOnUpdate = AlignOnUpdate.always;
    _gpsIcon =
        Icon(Icons.explore, color: Color.fromRGBO(0, 153, 255, 1), size: 35);
    _currentOption = 3;
    if (!mounted) {
      return;
    }
    setState(() {});
    _mapController
        .animatedRotateTo(_mapController.mapController.camera.rotation);
    _mapController.animatedZoomTo(18);
  }

  void _requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _toOption0();
      } else if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
            locationSettings: LocationSettings(
                accuracy: LocationAccuracy.best, distanceFilter: 10));
        _center = LatLng(position.latitude, position.longitude);
        if (widget.stopId == null) {
          _toOption2(position);
        } else {
          _toOption1();
        }
      } else if (permission == LocationPermission.deniedForever) {
        _gpsOn = false;
        _showEnableLocationDialog();
      }
    } catch (e) {
      _toOption0();
    }
  }

  void _listenToLocationServiceStatus() {
    _locationServiceStatusStream = Geolocator.getServiceStatusStream().listen(
      (ServiceStatus status) {
        if (status == ServiceStatus.disabled) {
          if (_currentOption != 0) {
            _toOption0();
          }
        } else if (status == ServiceStatus.enabled) {
          if (_currentOption == 0) {
            _toOption1();
          }
        }
      },
    );
  }

  void _changeLocationOption() async {
    if (_gpsOn) {
      try {
        if (_currentOption == 1) {
          _toOption2();
        } else if (_currentOption == 2) {
          _toOption3();
        } else if (_currentOption == 3) {
          _toOption2();
        }
      } catch (e) {
        _gpsOn = false;
        if (mounted) {
          setState(() {});
        }
        _showLocationDialog(
            "Unable to get current location. Please enable location services.");
      }
    } else {
      _requestLocationPermission();
    }
  }

  void _showEnableLocationDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Services Disabled'),
          content: Text(
              'Location services are disabled. Would you like to enable them?'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await permission.openAppSettings();
              },
              child: Text('Yes', style: TextStyle(color: Colors.blue[800])),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('No', style: TextStyle(color: Colors.blue[800])),
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
          FlutterMap(
            mapController: _mapController.mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 16.0,
              minZoom: 7.0,
              maxZoom: 18.0,
              cameraConstraint: CameraConstraint.contain(
                  bounds: LatLngBounds(
                      LatLng(42.29301588859787, -6.047089196299635),
                      LatLng(36.660350971821785, -10.027199015120786))),
              keepAlive: true,
              onMapEvent: (MapEvent event) {
                if (event is MapEventMoveStart) {
                  if (_currentOption > 1) {
                    _toOption1();
                  }
                }
                if (!_moving && _mapInfo) {
                  _mapInfo = false;
                  if (mounted) {
                    setState(() {});
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
              MarkerLayer(
                markers: _markersList,
              ),
              if (_gpsOn)
                CurrentLocationLayer(
                  alignPositionOnUpdate: _alignOnUpdate,
                  alignDirectionOnUpdate: _alignOnUpdate,
                ),
              BusTracker(
                busTapped: _busTapped,
              ),
            ],
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
          if (_mapInfo)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: ElevatedButton(
                  onPressed: () {
                    _mapInfo = false;
                    if (mounted) {
                      setState(() {});
                    }
                    Navigator.push(
                      context,
                      _selected is models.Stop
                          ? MaterialPageRoute(
                              builder: (context) => ScheduleScreen(
                                stop: _selected,
                                screenClosed: () {},
                              ),
                            )
                          : MaterialPageRoute(
                              builder: (context) => BusScreen(
                                busId: _selected,
                              ),
                            ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 1,
                    side: BorderSide(color: Colors.grey, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(45.0),
                    ),
                  ),
                  child: SizedBox(
                    height: 70,
                    child: _info,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
