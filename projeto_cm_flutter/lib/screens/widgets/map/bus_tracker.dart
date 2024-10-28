import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:projeto_cm_flutter/isar/models.dart' as models;
import 'package:projeto_cm_flutter/services/database_service.dart';
import 'package:projeto_cm_flutter/state/app_state.dart';
import 'package:provider/provider.dart';

class Itinerarie {
  final String id;
  final String name;
  final int divsPerLine;
  final List<LatLng> stops;

  Itinerarie({
    required this.id,
    required this.name,
    required this.divsPerLine,
    required this.stops,
  });
}

class BusTracker extends StatefulWidget {
  const BusTracker({super.key, required this.busTapped});
  final Function busTapped;

  @override
  _BusTrackerState createState() => _BusTrackerState();
}

class _BusTrackerState extends State<BusTracker> {
  DatabaseService dbService = DatabaseService.getInstance();
  final int _updateIntervalSeconds = 1;

  static LatLng _position1 = LatLng(0, 0);
  static LatLng _position2 = LatLng(0, 0);
  static LatLng _position3 = LatLng(0, 0);

  static late Itinerarie _it1;
  static late Itinerarie _it2;
  static late Itinerarie _it3;

  bool _showBusTracker = false;

  late AppState appState;

  @override
  void initState() {
    super.initState();

    _generateBuses();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      appState = Provider.of<AppState>(context, listen: false);
      _showBusTracker = appState.connectionStatus;
      setState(() {});
      appState.addListener(() {
        _showBusTracker = appState.connectionStatus;
        setState(() {});
      });
    });
  }

  @override
  void dispose() {
    appState.removeListener(() {});
    super.dispose();
  }

  Future<Itinerarie> _generateItinerary(String path) async {
    List<String> lines = path.split('\n');
    String id = lines[0].toString().trim();

    models.Bus? bus = await dbService.getBusById(id);

    int divsPerLine = int.parse(lines[1]);
    List<LatLng> stops = [];
    for (int i = 2; i < lines.length; i++) {
      List<String> coords = lines[i].split(' ');
      double lat = double.parse(coords[0]);
      double long = double.parse(coords[1]);

      if (i > 2) {
        LatLng lastStop = stops[stops.length - 1];
        double latDiff = (lat - lastStop.latitude) / divsPerLine;
        double longDiff = (long - lastStop.longitude) / divsPerLine;

        for (int j = 0; j < divsPerLine; j++) {
          stops.add(LatLng(lastStop.latitude + latDiff * j, lastStop.longitude + longDiff * j));
        }
      }

      stops.add(LatLng(lat, long));
    }

    return Itinerarie(id: id, name: bus!.busName!, divsPerLine: divsPerLine, stops: stops);
  }

  void _generateBuses() async {
    final String linha11 = await rootBundle.loadString('assets/itineraries/linha_11.txt');
    final String linha5_santiago = await rootBundle.loadString('assets/itineraries/linha_5_santiago.txt');
    final String linha5_solposto = await rootBundle.loadString('assets/itineraries/linha_5_solposto.txt');

    _it1 = await _generateItinerary(linha11);
    _it2 = await _generateItinerary(linha5_santiago);
    _it3 = await _generateItinerary(linha5_solposto);

    int bus1Index = _updateIntervalSeconds;
    int bus2Index = _updateIntervalSeconds;
    int bus3Index = _updateIntervalSeconds;

    _position1 = _it1.stops[bus1Index];
    _position2 = _it2.stops[bus2Index];
    _position3 = _it3.stops[bus3Index];

    while (true) {
      await Future.delayed(Duration(seconds: _updateIntervalSeconds));
      if (bus1Index >= _it1.stops.length) {
        bus1Index = 0;
      }
      if (bus2Index >= _it2.stops.length) {
        bus2Index = 0;
      }
      if (bus3Index >= _it3.stops.length) {
        bus3Index = 0;
      }

      _position1 = _it1.stops[bus1Index];
      _position2 = _it2.stops[bus2Index];
      _position3 = _it3.stops[bus3Index];

      bus1Index += _updateIntervalSeconds;
      bus2Index += _updateIntervalSeconds;
      bus3Index += _updateIntervalSeconds;

      if (!mounted) return;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: _showBusTracker,
      child: MarkerLayer(
        markers: [
          Marker(
            width: 40.0,
            height: 40.0,
            point: _position1,
            rotate: true,
            child: GestureDetector(
              onTap: () {
                widget.busTapped(_position1, _it1, _updateIntervalSeconds);
              },
              child: Icon(
                Icons.directions_bus,
                color: Colors.purple,
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
          ),
          Marker(
            width: 40.0,
            height: 40.0,
            point: _position2,
            rotate: true,
            child: GestureDetector(
              onTap: () {
                widget.busTapped(_position2, _it2, _updateIntervalSeconds);
              },
              child: Icon(
                Icons.directions_bus,
                color: Colors.green,
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
          ),
          Marker(
            width: 40.0,
            height: 40.0,
            point: _position3,
            rotate: true,
            child: GestureDetector(
              onTap: () {
                widget.busTapped(_position3, _it3, _updateIntervalSeconds);
              },
              child: Icon(
                Icons.directions_bus,
                color: Colors.green,
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
          ),
        ],
      ),
    );
  }
}
