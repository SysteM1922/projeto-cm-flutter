import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:projeto_cm_flutter/services/database_service.dart';
import 'package:projeto_cm_flutter/screens/widgets/schedule/stop_icon.dart';

import 'package:projeto_cm_flutter/isar/models.dart' as models;
import 'package:projeto_cm_flutter/state/app_state.dart';
import 'package:provider/provider.dart';

class RouteScreen extends StatefulWidget {
  final String routeId;

  const RouteScreen({super.key, required this.routeId});

  @override
  _RouteScreenState createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  models.Route? routeData;
  List<Map<String, dynamic>> busesData = [];
  bool isLoading = true;
  String errorMessage = "";

  final DatabaseService dbService = DatabaseService.getInstance();

  @override
  void initState() {
    super.initState();
    fetchRouteData();
  }

  Future<void> fetchRouteData() async {
    try {
      // Fetch the route with the given routeId
      final models.Route? route = await dbService.getRouteById(widget.routeId);

      if (route != null) {

        // Group busStops by busId
        Map<String, List<models.BusStop>> busStopsByBusId = {};

        for (var busStop in route.busStops) {
          String busId = busStop.busId ?? '';
          if (busId.isEmpty) continue;

          if (!busStopsByBusId.containsKey(busId)) {
            busStopsByBusId[busId] = [];
          }
          busStopsByBusId[busId]!.add(busStop);
        }

        // For each busId, create a bus object and assign stops
        List<Map<String, dynamic>> busesDataTemp = [];

        for (var busId in busStopsByBusId.keys) {
          // Fetch bus details
          final bus = await dbService.getBusById(busId);

          if (bus != null) {
            List<models.BusStop> busStopsForBus = busStopsByBusId[busId]!;

            busStopsForBus
                .sort((a, b) => a.arrivalTime!.compareTo(b.arrivalTime!));

            List<Map<String, dynamic>> stopsData = [];

            for (var busStop in busStopsForBus) {
              final stop =
                  await dbService.getStopByServerId(busStop.stopId ?? '');

              if (stop != null) {
                stopsData.add({
                  'stop_id': stop.serverId,
                  'stop_name': stop.stopName != null
                      ? utf8.decode(stop.stopName!.runes.toList())
                      : 'Stop',
                  'arrival_time': busStop.arrivalTime?.toIso8601String(),
                  'isFirstStop': false, // set this later
                  'isLastStop': false, // set this later
                });
              }
            }

            if (stopsData.isNotEmpty) {
              // Mark first and last stops
              stopsData.first['isFirstStop'] = true;
              stopsData.last['isLastStop'] = true;
            }

            busesDataTemp.add({
              'bus_id': bus.serverId,
              'bus_name': bus.busName,
              'stops': stopsData,
            });
          }
        }

        setState(() {
          routeData = route;
          busesData = busesDataTemp;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = "Route not found in the database.";
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        isLoading = false;
        errorMessage = "Error fetching route data: $e";
      });
      debugPrint("Error fetching route data: $e");
    }
  }

  @override
  void dispose() {
    // Do not close Isar here
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String routeName = routeData?.routeName != null
        ? utf8.decode(routeData!.routeName!.runes.toList())
        : 'Route';

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        shadowColor: Colors.black,
        title: Text(
          routeName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_outlined),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : routeData != null
              ? busesData.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ListView.builder(
                              itemCount: busesData.length,
                              itemBuilder: (context, index) {
                                final bus = busesData[index];
                                return _buildBusCard(bus, index);
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                  : Center(
                      child: Text(errorMessage.isNotEmpty
                          ? errorMessage
                          : "No buses available for this route."),
                    )
              : Center(
                  child: Text(errorMessage.isNotEmpty
                      ? errorMessage
                      : "Failed to load route details."),
                ),
    );
  }

  Widget _buildBusCard(Map<String, dynamic> bus, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        backgroundColor: Colors.blue[50],
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.blueAccent,
          child: Text(
            "${index + 1}",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          bus['bus_name'],
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        children: bus['stops'].map<Widget>((stop) {
          return _buildStopCard(stop);
        }).toList(),
      ),
    );
  }

  Widget _buildStopCard(Map<String, dynamic> stop) {
    bool isFirstStop = stop['isFirstStop'] ?? false;
    bool isLastStop = stop['isLastStop'] ?? false;
    String arrivalTime =
        stop['arrival_time']?.substring(11, 16) ?? '--:--'; // Extract time only

    return GestureDetector(
        onTap: () {
          WidgetsBinding.instance.addPostFrameCallback((_) {
          final appState = Provider.of<AppState>(context, listen: false);
          appState.navigateToMapWithStop(stop['stop_id']);
          Navigator.popUntil(context, (route) => route.isFirst);
        });
        },
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: StopIcon(isFirst: isFirstStop, isLast: isLastStop),
          title: Text(
            stop['stop_name'] ?? 'Stop',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          subtitle: Row(
            children: [
              const Icon(Icons.access_time, color: Colors.green, size: 14),
              const SizedBox(width: 5),
              Text(
                "Arrival Time: $arrivalTime",
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ));
  }
}
