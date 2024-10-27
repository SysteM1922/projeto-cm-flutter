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
      log("Attempting to read 'user_name' from secure storage.");
      String? userName = await _storage.read(key: "user_name");
      log("Retrieved 'user_name': $userName");

      log("Attempting to read 'user_id' from secure storage.");
      String? userId = await _storage.read(key: "user_id");
      log("Retrieved 'user_id': $userId");

      setState(() {
        _userName = userName ?? 'UserName';
        _userId = userId ?? '';
        log("Set _userName to: $_userName");
        log("Set _userId to: $_userId");
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
      log("Initial connectivity status: $connectivity");

      
      bool currentlyOffline = !connectivity.contains(ConnectivityResult.wifi) &&
          !connectivity.contains(ConnectivityResult.mobile) &&
          !connectivity.contains(ConnectivityResult.ethernet) &&
          !connectivity.contains(ConnectivityResult.vpn);

      setState(() {
        isOffline = currentlyOffline;
        log("isOffline set to: $isOffline");
      });

      if (!currentlyOffline) {
        log("Device is online. Fetching travel history...");
        await _fetchTravelHistory();
      } else {
        log("Device is offline. Attempting to load travel history from local storage.");
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
      log("Received connectivity update: $result");

      final wasOffline = isOffline;

      bool currentlyOffline = !result.contains(ConnectivityResult.wifi) &&
          !result.contains(ConnectivityResult.mobile) &&
          !result.contains(ConnectivityResult.ethernet) &&
          !result.contains(ConnectivityResult.vpn);

      setState(() {
        isOffline = currentlyOffline;
        log("isOffline set to: $isOffline");
      });

      if (currentlyOffline) {
        log("Device is offline.");
        setState(() {
          isLoading = false; 
        });
      } else {
        log("Device is online.");
        if (wasOffline) {
          log("Connection restored. Fetching travel history...");
          _fetchTravelHistory();
        }
      }
    });

    log("Connectivity listener initialized.");
  }

  Future<void> _fetchTravelHistory() async {
    log("Starting to fetch travel history...");
    setState(() {
      isLoading = true;
      log("isLoading set to true.");
    });

    if (_userId.isEmpty) {
      log("User ID is empty. Skipping fetch.");
      setState(() {
        isLoading = false;
        log("isLoading set to false.");
      });
      await _loadFromLocalStorage();
    }

    try {
      final apiUrl = dotenv.env['API_URL'] ?? '';
      final endpoint = '$apiUrl/user/history/$_userId';

      log("Fetching travel history from API: $endpoint");

      final response = await http.get(Uri.parse(endpoint));
      log("Received response with status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        final historyList =
            data.map((item) => item as Map<String, dynamic>).toList();

        log("Fetched travel history data: $historyList");

        // Save to Isar
        await _saveToLocalStorage(historyList);
        log("Saved travel history to local storage.");

        setState(() {
          travelHistory = historyList;
          log("Updated travelHistory state.");
        });
      } else {
        log('Failed to fetch data from API. Status code: ${response.statusCode}');
      }
    } catch (e) {
      log('Error fetching travel history from API: $e');
    }

    setState(() {
      isLoading = false;
      log("Finished fetching travel history. isLoading set to false.");
    });
  }

  Future<void> _saveToLocalStorage(
      List<Map<String, dynamic>> historyList) async {
    try {
      // Clear existing travel history before saving new data
      await _databaseService.clearTravelHistory();
      log("Cleared existing travel history in local storage.");

      final travelHistoryModels = historyList
          .map((item) => models.TravelHistory()
            ..routeNumber = item['route_number'] ?? 'Unknown Route'
            ..date = DateTime.parse(item['date']))
          .toList();

      log("Converted travel history data to models: $travelHistoryModels");

      // Save to Isar
      await _databaseService.saveTravelHistory(travelHistoryModels);
      log("Saved TravelHistory models to Isar.");
    } catch (e) {
      log('Error saving to local storage: $e');
    }
  }

  Future<void> _loadFromLocalStorage() async {
    try {
      final localHistory = await _databaseService.getTravelHistory();
      log("Loaded local travel history: $localHistory");

      setState(() {
        travelHistory = localHistory
            .map((history) => {
                  'route_number': history.routeNumber,
                  'date': history.date?.toIso8601String(),
                })
            .toList();
        log("Updated travelHistory from local storage: $travelHistory");
      });
    } catch (e) {
      log('Error loading from local storage: $e');
      setState(() {
        travelHistory = [];
        log("Set travelHistory to empty due to error.");
      });
    }
  }

  void _signOut(BuildContext context) async {
    log("Signing out user...");
    await FirebaseAuth.instance.signOut();
    await _storage.deleteAll();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('biometrics', false);
    log("Cleared secure storage and biometrics preference.");

    // Clear travel history from User
    await _databaseService.clearTravelHistory();
    log("Cleared travel history from local storage.");

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _connectionServiceStatusStream?.cancel();
    log("Disposed connectivity listener.");
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
                child: const Icon(Icons.person, size: 100),
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
              : Column(
                  children: [
                    Expanded(
                      child: _buildTravelHistory(),
                    ),
                  ],
                ),
        ),
      ],
    ));
  }


  Widget _buildTravelHistory() {
    if (travelHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey,
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
                            formattedDate =
                                DateFormat('MMM dd, yyyy - HH:mm')
                                    .format(travelDate);
                            log(
                                "Parsed date: $formattedDate for route: $routeNumber");
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
