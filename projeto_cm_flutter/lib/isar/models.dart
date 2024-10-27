import 'package:isar/isar.dart';

part 'models.g.dart';

@collection
class Stop {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  String? serverId;
  String? stopName;
  double? latitude;
  double? longitude;
  final busStops = IsarLinks<BusStop>();

  Stop();

  factory Stop.fromJson(Map<String, dynamic> json) {
    final stop = Stop()
      ..serverId = json['id'].toString().trim()
      ..stopName = json['stop_name']
      ..latitude = json['stop_location_lat']
      ..longitude = json['stop_location_long'];
    return stop;
  }
}

@collection
class Route {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  String? serverId;
  @Index()
  String? routeName;
  int? routeNumber;
  final buses = IsarLinks<Bus>();
  final busStops = IsarLinks<BusStop>();

  Route();

  factory Route.fromJson(Map<String, dynamic> json) {
    final route = Route()
      ..serverId = json['id'].toString().trim()
      ..routeName = json['route_name']
      ..routeNumber = json['route_number'];
    return route;
  }
}

@collection
class Bus {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  String? serverId;
  String? busName;
  String? routeId;
  final busStops = IsarLinks<BusStop>();

  Bus();

  factory Bus.fromJson(Map<String, dynamic> json) {
    final bus = Bus()
      ..serverId = json['id'].toString().trim()
      ..busName = json['bus_name']
      ..routeId = json['route_id'].toString().trim();
    return bus;
  }
}

@collection
class BusStop {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  String? serverId;
  DateTime? arrivalTime;
  String? stopId;
  String? busId;
  String? routeId;

  BusStop();

  factory BusStop.fromJson(Map<String, dynamic> json) {
    final busStop = BusStop()
      ..serverId = json['id'].toString().trim()
      ..arrivalTime = DateTime.parse(json['stop_time'])
      ..stopId = json['stop_id'].toString().trim()
      ..busId = json['bus_id'].toString().trim()
      ..routeId = json['route_id'].toString().trim();
    return busStop;
  }
}


@collection
class TravelHistory {
  Id id = Isar.autoIncrement;
  String? routeNumber;
  DateTime? date;

  TravelHistory();

  factory TravelHistory.fromJson(Map<String, dynamic> json) {
    final history = TravelHistory()
      ..routeNumber = json['route_number']
      ..date = DateTime.parse(json['date']);
    return history;
  }
}