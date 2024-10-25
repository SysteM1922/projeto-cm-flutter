import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:isar/isar.dart';
import 'package:projeto_cm_flutter/services/isar_service.dart'; // To get the Isar instance
import 'package:projeto_cm_flutter/isar/models.dart' as models;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();

  late Isar isar;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late String apiUrl;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal() {
    apiUrl = dotenv.env['API_URL'] ?? '';
    _initializeIsar();
  }

  Future<void> _initializeIsar() async {
    isar = await IsarService.getInstance();
  }

  Future<models.Stop?> getStopById(String stopId) async {
    return await isar.stops
        .filter()
        .serverIdEqualTo(stopId)
        .findFirst();
  }

  Future<List<models.BusStop>> getBusStopsByStopId(String stopId) async {
    return await isar.busStops
        .filter()
        .stopIdEqualTo(stopId)
        .findAll();
  }

  Future<models.Route?> getRouteById(String routeId) async {
    return await isar.routes
        .filter()
        .serverIdEqualTo(routeId)
        .findFirst();
  }

  Future<List<models.BusStop>> getBusStopsByRouteId(String routeId) async {
    return await isar.busStops
        .filter()
        .routeIdEqualTo(routeId)
        .findAll();
  }

  Future<models.Bus?> getBusById(String busId) async {
    return await isar.bus
        .filter()
        .serverIdEqualTo(busId)
        .findFirst();
  }

  Future<models.Stop?> getStopByServerId(String stopId) async {
    return await isar.stops
        .filter()
        .serverIdEqualTo(stopId)
        .findFirst();
  }

  Future<bool> isDatabaseUpdated() async {
    String? lastUpdate = await _storage.read(key: 'last_update');
    lastUpdate ??= "1970-01-01 00:00:00.1";

    // check if the data is up-to-date
    try {
      final response = await http.get(Uri.parse('$apiUrl/system/last_update'));

      if (response.statusCode == 200) {
        // Data is up-to-date
        await _storage.write(key: 'last_update', value: DateTime.now().toIso8601String());
        return true;
      } else if (response.statusCode == 404) {
        // Data is outdated
        return false;
      } else {
        // Some error occurred
        return false;
      }
    } catch (e) {
      // Error occurred
      return false;
    }
  }
Future<void> updateDatabase() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/system/last_update'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> routes = data['routes'];
        final List<dynamic> stops = data['stops'];
        final List<dynamic> buses = data['buses'];
        final List<dynamic> busStops = data['bus_stops'];
        final String lastUpdate = data['last_updated'];

        // Ensure Isar is initialized
        if (isar == null) {
          await _initializeIsar();
        }

        // Clear existing data
        await isar.writeTxn(() async {
          await isar.routes.clear();
          await isar.stops.clear();
          await isar.bus.clear();
          await isar.busStops.clear();
        });

        // Parse and insert data
        List<models.BusStop> busStopList = busStops.map((json) => models.BusStop.fromJson(json)).toList();

        List<models.Route> routeList = routes.map((json) {
          models.Route routeModel = models.Route.fromJson(json);
          routeModel.busStops.addAll(busStopList.where((element) => element.routeId == routeModel.serverId));
          return routeModel;
        }).toList();

        List<models.Stop> stopList = stops.map((json) {
          models.Stop stopModel = models.Stop.fromJson(json);
          stopModel.busStops.addAll(busStopList.where((element) => element.stopId == stopModel.serverId));
          return stopModel;
        }).toList();

        List<models.Bus> busList = buses.map((json) {
          models.Bus busModel = models.Bus.fromJson(json);
          busModel.busStops.addAll(busStopList.where((element) => element.busId == busModel.serverId));
          return busModel;
        }).toList();

        // Insert data into Isar
        await isar.writeTxn(() async {
          await isar.busStops.putAll(busStopList);
          await isar.routes.putAll(routeList);
          await isar.stops.putAll(stopList);
          await isar.bus.putAll(busList);
        });

        await _storage.write(key: 'last_update', value: lastUpdate);
      } else {
        // Handle error
        throw Exception('Failed to update database. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Handle error
      throw Exception('Error updating database: $e');
    }
  }
}