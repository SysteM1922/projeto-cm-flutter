import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ResultScreen extends StatefulWidget {
  final String code;
  final VoidCallback screenClosed;

  const ResultScreen({Key? key, required this.code, required this.screenClosed})
      : super(key: key);

  @override
  _ResultScreenState createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  List<dynamic>? busSchedules;
  bool isLoading = true;

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
        setState(() {
          busSchedules = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          busSchedules = null;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        busSchedules = null;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bus Schedule"),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            widget.screenClosed();
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_outlined),
        ),
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : busSchedules != null
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView.builder(
                      itemCount: busSchedules!.length,
                      itemBuilder: (context, index) {
                        final schedule = busSchedules![index];
                        return _buildBusScheduleCard(schedule);
                      },
                    ),
                  )
                : const Text("Failed to load schedule."),
      ),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Route: ${schedule['route_number']}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Arrival Time:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
