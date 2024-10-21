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
        title: const Text("Found Schedule"),
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
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Scanned Code:",
                          style: TextStyle(fontSize: 20),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          widget.code,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          // print data
                          child: ListView.builder(
                            itemCount: busSchedules!.length,
                            itemBuilder: (context, index) {
                              final schedule = busSchedules![index];
                              return ListTile(
                                title: Text(
                                  "Route: ${schedule['route_number']} - Bus ID: ${schedule['bus_id']}",
                                  style: const TextStyle(fontSize: 16),
                                ),
                                subtitle: Text(
                                  "Arrival Time: ${schedule['arrival_time']}",
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                : const Text("Failed to load schedule."),
      ),
    );
  }
}
