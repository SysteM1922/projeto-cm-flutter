import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:projeto_cm_flutter/isar/models.dart' as models;
import 'package:projeto_cm_flutter/screens/route_screen.dart';
import 'package:projeto_cm_flutter/services/database_service.dart';
import 'package:projeto_cm_flutter/screens/widgets/schedule/stop_icon.dart';
import 'package:projeto_cm_flutter/state/app_state.dart';
import 'package:provider/provider.dart';

class BusScreen extends StatefulWidget {
  const BusScreen({super.key, required this.busId});
  final String busId;

  @override
  _BusScreenState createState() => _BusScreenState();
}

class _BusScreenState extends State<BusScreen> {
  final DatabaseService dbService = DatabaseService.getInstance();

  Map<String, dynamic> busData = {};

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    _fetchBusData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchBusData() async {
    models.Bus? bus = await dbService.getBusById(widget.busId);

    if (bus != null) {
      List<models.BusStop> busStopsForBus = bus.busStops.toList();

      busStopsForBus.sort((a, b) => a.arrivalTime!.compareTo(b.arrivalTime!));

      List<Map<String, dynamic>> stopsData = [];

      for (var busStop in busStopsForBus) {
        final stop = await dbService.getStopByServerId(busStop.stopId ?? '');

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

      models.Route? route = await dbService.getRouteById(bus.routeId!);

      busData = {
        'bus_id': bus.serverId,
        'bus_name': bus.busName,
        'route_id': bus.routeId,
        'route_name': route?.routeName,
        'stops': stopsData,
      };
    }

    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        shadowColor: Colors.black,
        title: Text(
          busData['bus_name'] ?? 'Bus',
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
          : busData.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: busData['stops'].length,
                          itemBuilder: (context, index) {
                            final stop = busData['stops'][index];
                            return _buildStopCard(stop);
                          },
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(
                              top: 16, right: 16, left: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  elevation: 5,
                                  backgroundColor: Colors.blueAccent,
                                  padding: const EdgeInsets.all(10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RouteScreen(
                                        routeId: busData['route_id'],
                                      ),
                                    ),
                                  );
                                },
                                child: Center(
                                  child: Text(
                                    busData['route_name'] ?? 'Route',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const Center(child: Text('Bus not found in the database.')),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 32),
        leading: StopIcon(isFirst: isFirstStop, isLast: isLastStop),
        title: Text(
          stop['stop_name'] ?? 'Stop',
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
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
      ),
    );
  }
}
