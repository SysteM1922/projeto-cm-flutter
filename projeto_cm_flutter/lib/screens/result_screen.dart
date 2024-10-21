import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projeto_cm_flutter/screens/route_screen.dart';

class ResultScreen extends StatefulWidget {
  final String code;
  final VoidCallback screenClosed;

  const ResultScreen({Key? key, required this.code, required this.screenClosed}) : super(key: key);

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

        // get stop_name and arrival_times from the response
        setState(() {
          stopName = data['stop_name'];
          arrivalTimes = data['arrival_times'];
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
                            : const Center(child: Text("No buses scheduled for this stop.")),
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
                Expanded( // Ensures text wraps correctly
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
                        overflow: TextOverflow.ellipsis, // Prevent overflow
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
