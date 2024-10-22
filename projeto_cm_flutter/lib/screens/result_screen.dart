import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projeto_cm_flutter/screens/route_screen.dart';

class ResultScreen extends StatefulWidget {
  final String code;
  final VoidCallback screenClosed;

  const ResultScreen({super.key, required this.code, required this.screenClosed});

  @override
  _ResultScreenState createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  List<dynamic>? arrivalTimes;
  bool isLoading = true;
  String stopName = "Loading...";

  @override
  void initState() {
    super.initState();
    fetchBusSchedules();
  }

  Future<void> fetchBusSchedules() async {
    final Uri url = Uri.parse(widget.code);

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        var data = json.decode(utf8.decode(response.bodyBytes));

        // Process arrival times to keep only the earliest arrival for each bus_id
        List<dynamic> processedArrivalTimes = processArrivalTimes(data['arrival_times']);

        // get stop_name and arrival_times from the response
        setState(() {
          stopName = data['stop_name'];
          arrivalTimes = processedArrivalTimes;
          isLoading = false;
        });
      } else {
        setState(() {
          arrivalTimes = null;
          isLoading = false;
        });
        debugPrint("Failed to fetch bus schedules. Status code: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        arrivalTimes = null;
        isLoading = false;
      });
      debugPrint("Error fetching bus schedules: $e");
    }
  }

  // Function to process arrival times
  List<dynamic> processArrivalTimes(List<dynamic> arrivalTimes) {
    Map<String, dynamic> busSchedules = {};

    for (var schedule in arrivalTimes) {
      String busId = schedule['bus_id'].toString();
      String arrivalTimeStr = schedule['arrival_time'];

      // Parse the arrival time into DateTime
      DateTime arrivalTime = DateTime.parse(arrivalTimeStr);

      if (busSchedules.containsKey(busId)) {
        DateTime existingArrivalTime = DateTime.parse(busSchedules[busId]['arrival_time']);
        // Keep the schedule with the earliest arrival time
        if (arrivalTime.isBefore(existingArrivalTime)) {
          busSchedules[busId] = schedule;
        }
      } else {
        busSchedules[busId] = schedule;
      }
    }

    // Convert the busSchedules map values to a list
    List<dynamic> processedList = busSchedules.values.toList();

    // Sort the list by arrival time
    processedList.sort((a, b) => a['arrival_time'].compareTo(b['arrival_time']));

    return processedList;
  }

  @override
  Widget build(BuildContext context) {
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
          : arrivalTimes != null
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
                        child: arrivalTimes!.isNotEmpty
                            ? ListView.builder(
                                itemCount: arrivalTimes!.length,
                                itemBuilder: (context, index) {
                                  final schedule = arrivalTimes![index];
                                  return _buildBusScheduleCard(schedule);
                                },
                              )
                            : const Center(
                                child: Text("No buses scheduled for this stop.")),
                      ),
                    ],
                  ),
                )
              : const Center(child: Text("Failed to load schedule.")),
    );
  }

  Widget _buildBusScheduleCard(dynamic schedule) {
    String arrivalTime = schedule['arrival_time'].substring(11, 16);
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Route: ${schedule['route_number']}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                    ],
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
                        builder: (context) => RouteScreen(routeId: schedule['route_id']),
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
  }
}
