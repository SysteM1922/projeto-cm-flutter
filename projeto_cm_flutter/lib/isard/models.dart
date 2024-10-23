import 'package:isar/isar.dart';
import 'package:latlong2/latlong.dart';

@collection
class Stop {
  Id? id;
  String? stopName;
  @Index()
  LatLng? location;
}

@collection
class Route {
  Id? id;
  @Index()
  String? routeName;
  int? routeNumber;
}

@collection
class Bus {
  Id? id;
  String? busName;
  @Index()
  Route? route;
}

@collection
class BusStop {
  Id? id;
  @Index()
  Bus? bus;
  @Index()
  Stop? stop;
  Route? route;
  DateTime? arrivalTime;
}