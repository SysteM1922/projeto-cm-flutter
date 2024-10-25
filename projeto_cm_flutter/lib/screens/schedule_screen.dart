import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:projeto_cm_flutter/screens/route_screen.dart';
import 'package:projeto_cm_flutter/services/database_service.dart'; 

import 'package:projeto_cm_flutter/isar/models.dart' as models;

class ScheduleScreen extends StatefulWidget {
  final models.Stop stop;
  final VoidCallback screenClosed;

  const ScheduleScreen({Key? key, required this.stop, required this.screenClosed}) : super(key: key);

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List<models.BusStop> arrivalTimes = [];
  bool isLoading = true;

  final DatabaseService dbService = DatabaseService.getInstance();

  @override
  void initState() {
    super.initState();

    // print("Stop_id: ${widget.stop.serverId}");

    fetchBusSchedules();
  }

  Future<void> fetchBusSchedules() async {
    try {
      // Query bus stops associated with the stop's serverId
      final List<models.BusStop> busStops = await dbService.getBusStopsByStopId(widget.stop.serverId ?? '');

      // Process arrival times to keep only the earliest arrival for each bus_id
      List<models.BusStop> processedArrivalTimes = processArrivalTimes(busStops);

      if (!mounted) {
        return;
      }
      setState(() {
        arrivalTimes = processedArrivalTimes;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        arrivalTimes = [];
        isLoading = false;
      });
      debugPrint("Error fetching bus schedules: $e");
    }
  }

  List<models.BusStop> processArrivalTimes(List<models.BusStop> busStops) {
    Map<String, models.BusStop> busSchedules = {};

    for (var schedule in busStops) {
      String busId = schedule.busId ?? '';
      DateTime? arrivalTime = schedule.arrivalTime;

      if (arrivalTime == null || busId.isEmpty) continue;

      if (busSchedules.containsKey(busId)) {
        DateTime existingArrivalTime = busSchedules[busId]!.arrivalTime!;
        // Keep the schedule with the earliest arrival time
        if (arrivalTime.isBefore(existingArrivalTime)) {
          busSchedules[busId] = schedule;
        }
      } else {
        busSchedules[busId] = schedule;
      }
    }
    // Convert the busSchedules map values to a list
    List<models.BusStop> processedList = busSchedules.values.toList();

    // Sort the list by arrival time
    processedList.sort((a, b) => a.arrivalTime!.compareTo(b.arrivalTime!));

    return processedList;
  }

  @override
  void dispose() {
    // Do not close Isar instance
    widget.screenClosed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String stopName = widget.stop.stopName != null
        ? utf8.decode(widget.stop.stopName!.runes.toList())
        : 'Stop';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Stop Schedule"),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            widget.screenClosed();
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_outlined),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : arrivalTimes.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'Stop: $stopName',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: arrivalTimes.length,
                          itemBuilder: (context, index) {
                            final schedule = arrivalTimes[index];
                            return _buildBusScheduleCard(schedule);
                          },
                        ),
                      ),
                    ],
                  ),
                )
              : const Center(child: Text("No buses scheduled for this stop.")),
    );
  }

  Widget _buildBusScheduleCard(models.BusStop schedule) {
    String arrivalTime = schedule.arrivalTime?.toLocal().toString().substring(11, 16) ?? '--:--';
    String routeNumber = '';

    return FutureBuilder<models.Route?>(
      future: dbService.getRouteById(schedule.routeId ?? ''),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          routeNumber = snapshot.data!.routeNumber?.toString() ?? '';
        }

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          elevation: 5,
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.directions_bus, size: 40, color: Colors.blue),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        "Route: $routeNumber",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 8),
                        const Icon(Icons.access_time, color: Colors.green),
                        const SizedBox(width: 5),
                        Text(
                          arrivalTime,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RouteScreen(routeId: schedule.routeId ?? ''),
                          ),
                        );
                      },
                      child: const Text("View Details"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
