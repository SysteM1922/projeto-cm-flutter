import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:flutter_map/flutter_map.dart';

class Itinerarie {
  final String id;
  final int divsPerLine;
  final List<latlong.LatLng> stops;

  Itinerarie({
    required this.id,
    required this.divsPerLine,
    required this.stops,
  });
}

class BusTracker extends StatefulWidget {
  const BusTracker({Key? key}) : super(key: key);

  @override
  _BusTrackerState createState() => _BusTrackerState();
}

class _BusTrackerState extends State<BusTracker> {
  int _updateIntervalSeconds = 1;

  latlong.LatLng _position1 = latlong.LatLng(0, 0);
  latlong.LatLng _position2 = latlong.LatLng(0, 0);
  latlong.LatLng _position3 = latlong.LatLng(0, 0);

  @override
  void initState() {
    super.initState();

    _generateBuses();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Itinerarie _generateItinerary(String path) {
    List<String> lines = path.split('\n');
    String id = lines[0];
    int divsPerLine = int.parse(lines[1]);
    List<latlong.LatLng> stops = [];
    for (int i = 2; i < lines.length; i++) {
      List<String> coords = lines[i].split(' ');
      double lat = double.parse(coords[0]);
      double long = double.parse(coords[1]);

      if (i > 2) {
        latlong.LatLng lastStop = stops[stops.length - 1];
        double latDiff = (lat - lastStop.latitude) / divsPerLine;
        double longDiff = (long - lastStop.longitude) / divsPerLine;

        for (int j = 0; j < divsPerLine; j++) {
          stops.add(latlong.LatLng(lastStop.latitude + latDiff * j,
              lastStop.longitude + longDiff * j));
        }
      }

      stops.add(latlong.LatLng(lat, long));
    }

    return Itinerarie(id: id, divsPerLine: divsPerLine, stops: stops);
  }

  void _generateBuses() async {
    final String linha11 =
        await rootBundle.loadString('assets/itineraries/linha_11.txt');
    final String linha5_santiago =
        await rootBundle.loadString('assets/itineraries/linha_5_santiago.txt');
    final String linha5_solposto =
        await rootBundle.loadString('assets/itineraries/linha_5_solposto.txt');

    Itinerarie it1 = _generateItinerary(linha11);
    Itinerarie it2 = _generateItinerary(linha5_santiago);
    Itinerarie it3 = _generateItinerary(linha5_solposto);

    int bus1Index = _updateIntervalSeconds;
    int bus2Index = _updateIntervalSeconds;
    int bus3Index = _updateIntervalSeconds;

    _position1 = it1.stops[bus1Index];
    _position2 = it2.stops[bus2Index];
    _position3 = it3.stops[bus3Index];

    while (true) {
      await Future.delayed(Duration(seconds: _updateIntervalSeconds));
      if (bus1Index >= it1.stops.length) {
        bus1Index = 0;
      }
      if (bus2Index >= it2.stops.length) {
        bus2Index = 0;
      }
      if (bus3Index >= it3.stops.length) {
        bus3Index = 0;
      }

      _position1 = it1.stops[bus1Index];
      _position2 = it2.stops[bus2Index];
      _position3 = it3.stops[bus3Index];

      bus1Index += _updateIntervalSeconds;
      bus2Index += _updateIntervalSeconds;
      bus3Index += _updateIntervalSeconds;

      if (!mounted) return;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(markers: [
      Marker(
        width: 40.0,
        height: 40.0,
        point: _position1,
        child: GestureDetector(
          onTap: () {
            log('Bus 1 tapped');
          },
          child: Icon(
            Icons.directions_bus_filled,
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
        child: GestureDetector(
          onTap: () {
            log('Bus 2 tapped');
          },
          child: Icon(
            Icons.directions_bus_filled,
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
        child: GestureDetector(
          onTap: () {
            log('Bus 3 tapped');
          },
          child: Icon(
            Icons.directions_bus_filled,
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
    ]);
  }
}
