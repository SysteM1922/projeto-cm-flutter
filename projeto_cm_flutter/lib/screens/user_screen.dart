import 'dart:convert';
import 'dart:developer';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:projeto_cm_flutter/screens/login_screen.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({Key? key}) : super(key: key);

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final _storage = const FlutterSecureStorage();

  String _userName = 'UserName';
  String _userId = '';
  bool isLoading = true;
  bool isOffline = false;
  String errorMessage = '';

  List<Map<String, dynamic>> travelHistory = [];

  StreamSubscription<List<ConnectivityResult>>? _connectionServiceStatusStream;

  @override
  void initState() {
    super.initState();
    _listenToConnectionServiceStatus();
    _fetchTravelHistory();
  }

  Future<void> _getUserInfo() async {
    String? userName = await _storage.read(key: "user_name");
    String? userId = await _storage.read(key: "user_id");
    
    setState(() {
      _userName = userName ?? 'UserName';
      _userId = userId ?? '';
    });
  }

  void _listenToConnectionServiceStatus() async {
    _connectionServiceStatusStream = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      if (!result.contains(ConnectivityResult.wifi) &&
          !result.contains(ConnectivityResult.mobile) &&
          !result.contains(ConnectivityResult.ethernet) &&
          !result.contains(ConnectivityResult.vpn)) {
        setState(() {
          isOffline = true;
        });
      } else {
        setState(() {
          isOffline = false;
        });
      }
    });
  }

  Future<void> _fetchTravelHistory() async {
    await _getUserInfo();

    if (_userId.isEmpty) {
      setState(() {
        errorMessage = 'User ID not found. Please log in again.';
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String apiUrl = 'http://51.138.34.104';
      String endpoint = '$apiUrl/user/history/$_userId';

      final response = await http.get(Uri.parse(endpoint));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));

        setState(() {
          travelHistory =
              data.map((item) => item as Map<String, dynamic>).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              'Failed to load travel history. Status code: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching travel history: $e';
        isLoading = false;
      });
    }
  }

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    await _storage.deleteAll(); // Clear all stored data
    // Navigate back to the LoginScreen
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _connectionServiceStatusStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      children: [
        const SizedBox(height: 50),
        Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                padding: const EdgeInsets.only(right: 20),
                icon: const Icon(Icons.logout),
                onPressed: () => _signOut(context),
              ),
            ]),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue[800],
                radius: 60,
                child: Icon(Icons.person, size: 100),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Center(
                  child: Text(
                    _userName,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : isOffline
                  ? const Center(
                      child: Text(
                          'You need to be online to check your past travels.'))
                  : errorMessage.isNotEmpty
                      ? Center(child: Text(errorMessage))
                      : _buildTravelHistory(),
        ),
      ],
    ));
  }

  Widget _buildTravelHistory() {
    if (travelHistory.isEmpty) {
      return const Center(
        child: Text(
          'No travel history available.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue.shade200, width: 2),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                backgroundColor: Colors.white,
                collapsedBackgroundColor: Colors.white,
                title: const Text(
                  'Travel History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.history,
                    color: Colors.blue,
                    size: 28,
                  ),
                ),
                children: [
                  Container(
                    constraints: const BoxConstraints(maxHeight: 470),
                    child: SingleChildScrollView(
                      child: Column(
                        children: travelHistory.map((travel) {
                          final routeNumber =
                              travel['route_number'] ?? 'Unknown Route';
                          final rawDate = travel['date'] ?? '';

                          DateTime? travelDate;
                          String formattedDate = 'Unknown Date';

                          try {
                            travelDate = DateTime.parse(rawDate);
                            formattedDate = DateFormat('MMM dd, yyyy - HH:mm')
                                .format(travelDate);
                          } catch (e) {
                            log('Error parsing date: $e');
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 1,
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(15),
                                title: Text(
                                  'Route $routeNumber',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  formattedDate,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                leading: const Icon(
                                  Icons.directions_bus,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
