import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:projeto_cm_flutter/widgets/stop_icon.dart';

class RouteScreen extends StatefulWidget {
  final String routeId;

  const RouteScreen({Key? key, required this.routeId}) : super(key: key);

  @override
  _RouteScreenState createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  Map<String, dynamic>? routeData;
  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    fetchRouteData();
  }

  Future<void> fetchRouteData() async {
    final String? apiUrl = dotenv.env['API_URL'];
    if (apiUrl == null || apiUrl.isEmpty) {
      setState(() {
        isLoading = false;
        errorMessage = "API URL not configured.";
      });
      return;
    }

    final Uri url = Uri.parse('${apiUrl}/route/${widget.routeId}');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          routeData = json.decode(utf8.decode(response.bodyBytes));
          isLoading = false;
        });
      } else {
        setState(() {
          routeData = null;
          isLoading = false;
          errorMessage =
              "Failed to load route. Status code: ${response.statusCode}";
        });
        debugPrint(
            "Failed to fetch data. Status code: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        routeData = null;
        isLoading = false;
        errorMessage = "Error fetching route data: $e";
      });
      debugPrint("Error fetching route data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Route Schedule Details"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : routeData != null
              ? routeData!['buses'].isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                routeData![
                                    'route_name'], 
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                              height:
                                  16), 
                          Expanded(
                            child: ListView.builder(
                              itemCount: routeData!['buses'].length,
                              itemBuilder: (context, index) {
                                final bus = routeData!['buses'][index];
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
                          : "No buses available for this route."))
              : Center(
                  child: Text(errorMessage.isNotEmpty
                      ? errorMessage
                      : "Failed to load route details.")),
    );
  }

  // styled card for each bus with a dropdown for the stops
  Widget _buildBusCard(dynamic bus, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: ExpansionTile(
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
          "Bus ${index + 1}",
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        children: bus['stops'].map<Widget>((stop) {
          return _buildStopCard(
              stop, bus['stops'].indexOf(stop), bus['stops'].length);
        }).toList(),
      ),
    );
  }

  Widget _buildStopCard(dynamic stop, int index, int totalStops) {
    bool isFirstStop = index == 0;
    bool isLastStop = index == totalStops - 1; // Check if it's the last stop
    String arrivalTime =
        stop['arrival_time'].substring(11, 16); // Extract time only

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: StopIcon(isFirst: isFirstStop, isLast: isLastStop),
      title: Text(
        stop['stop_name'],
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
    );
  }
}
