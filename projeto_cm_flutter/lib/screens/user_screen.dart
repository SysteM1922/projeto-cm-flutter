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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projeto_cm_flutter/services/database_service.dart';
import 'package:projeto_cm_flutter/isar/models.dart' as models;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({Key? key}) : super(key: key);

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final _storage = const FlutterSecureStorage();
  final _databaseService = DatabaseService.getInstance();

  String _userName = 'UserName';
  String _userId = '';
  bool isLoading = true;
  bool isOffline = true;

  List<Map<String, dynamic>> travelHistory = [];

  StreamSubscription<List<ConnectivityResult>>? _connectionServiceStatusStream;

  @override
  void initState() {
    super.initState();
    _getUserInfo();
    _checkInitialConnectivity();
    _listenToConnectionServiceStatus();
  }

  Future<void> _getUserInfo() async {
    try {
      String? userName = await _storage.read(key: "user_name");

      String? userId = await _storage.read(key: "user_id");

      setState(() {
        _userName = userName ?? 'UserName';
        _userId = userId ?? '';
      });
    } catch (e) {
      log('Error retrieving user info from secure storage: $e');
      setState(() {
        _userName = 'UserName';
        _userId = '';
      });
    }
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();

      bool currentlyOffline = !connectivity.contains(ConnectivityResult.wifi) &&
          !connectivity.contains(ConnectivityResult.mobile) &&
          !connectivity.contains(ConnectivityResult.ethernet) &&
          !connectivity.contains(ConnectivityResult.vpn);

      setState(() {
        isOffline = currentlyOffline;
      });

      if (!currentlyOffline) {
        await _fetchTravelHistory();
      } else {
        await _loadFromLocalStorage();
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      log('Error during initial connectivity check: $e');
      setState(() {
        isOffline = true;
        isLoading = false;
      });
    }
  }

  void _listenToConnectionServiceStatus() {
    _connectionServiceStatusStream = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      final wasOffline = isOffline;

      bool currentlyOffline = !result.contains(ConnectivityResult.wifi) &&
          !result.contains(ConnectivityResult.mobile) &&
          !result.contains(ConnectivityResult.ethernet) &&
          !result.contains(ConnectivityResult.vpn);

      setState(() {
        isOffline = currentlyOffline;
      });

      if (currentlyOffline) {
        setState(() {
          isLoading = false;
        });
      } else {
        if (wasOffline) {
          _fetchTravelHistory();
        }
      }
    });
  }

  Future<void> _fetchTravelHistory() async {
    setState(() {
      isLoading = true;
    });

    if (_userId.isEmpty) {
      setState(() {
        isLoading = false;
      });
      await _loadFromLocalStorage();
    }

    try {
      final apiUrl = dotenv.env['API_URL'] ?? '';
      final endpoint = '$apiUrl/user/history/$_userId';

      final response = await http.get(Uri.parse(endpoint));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        final historyList =
            data.map((item) => item as Map<String, dynamic>).toList();

        // Save to Isar
        await _saveToLocalStorage(historyList);

        setState(() {
          travelHistory = historyList;
        });
      }
    } catch (e) {
      log('Error fetching travel history from API: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _saveToLocalStorage(
      List<Map<String, dynamic>> historyList) async {
    try {
      // Clear existing travel history before saving new data
      await _databaseService.clearTravelHistory();

      final travelHistoryModels = historyList
          .map((item) => models.TravelHistory()
            ..routeNumber = item['route_number'] ?? 'Unknown Route'
            ..date = DateTime.parse(item['date']))
          .toList();

      // Save to Isar
      await _databaseService.saveTravelHistory(travelHistoryModels);
    } catch (e) {
      log('Error saving to local storage: $e');
    }
  }

  Future<void> _loadFromLocalStorage() async {
    try {
      final localHistory = await _databaseService.getTravelHistory();

      setState(() {
        travelHistory = localHistory
            .map((history) => {
                  'route_number': history.routeNumber,
                  'date': history.date?.toIso8601String(),
                })
            .toList();
      });
    } catch (e) {
      log('Error loading from local storage: $e');
      setState(() {
        travelHistory = [];
      });
    }
  }

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    await _storage.deleteAll();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();

    // Clear travel history from User
    await _databaseService.clearTravelHistory();

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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    padding: const EdgeInsets.only(right: 10),
                    icon: const Icon(Icons.logout),
                    onPressed: () => _signOut(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue[800],
                    radius: 50,
                    child: const Icon(Icons.person, size: 60),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      _userName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildTravelHistory(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTravelHistory() {
    if (travelHistory.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No travel history available.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
          child: ExpansionTile(
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
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
              ListView.builder(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(), // no inner scrolling
                itemCount: travelHistory.length,
                itemBuilder: (context, index) {
                  final travel = travelHistory[index];
                  final routeNumber = travel['route_number'] ?? 'Unknown Route';
                  final rawDate = travel['date'] ?? '';

                  DateTime? travelDate;
                  String formattedDate = 'Unknown Date';

                  try {
                    travelDate = DateTime.parse(rawDate);
                    formattedDate =
                        DateFormat('MMM dd, yyyy - HH:mm').format(travelDate);
                  } catch (e) {
                    log('Error parsing date: $e');
                  }

                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 1,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 15),
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
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
