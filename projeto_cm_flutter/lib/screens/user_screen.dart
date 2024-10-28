import 'dart:convert';
import 'dart:developer';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:projeto_cm_flutter/screens/login_screen.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:projeto_cm_flutter/state/app_state.dart';
import 'package:provider/provider.dart';
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
  bool _isLoading = true;
  bool _isOffline = true;

  List<Map<String, dynamic>> travelHistory = [];

  late AppState appState;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      appState = Provider.of<AppState>(context, listen: false);
      _isOffline = !appState.connectionStatus;
      _getUserInfo().then((_) {
        _fetchTravelHistory();
      });
      appState.addListener(() {
        if (appState.connectionStatus) {
          _isOffline = false;
          _fetchTravelHistory();
        } else {
          _isOffline = true;
        }
      });
    });
  }

  @override
  void dispose() {
    appState.removeListener(() {});
    super.dispose();
  }

  Future<void> _getUserInfo() async {
    try {
      String? userName = await _storage.read(key: "user_name");

      String? userId = await _storage.read(key: "user_id");

      _userName = userName ?? 'UserName';
      _userId = userId ?? '';

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      log('Error retrieving user info from secure storage: $e');

      _userName = 'UserName';
      _userId = '';

      if (!mounted) return;
      setState(() {});
    }
  }

  Future<void> _fetchTravelHistory() async {
    if (_isOffline) {
      log('Device is offline. Loading travel history from local storage.');
      await _loadFromLocalStorage();
    } else {
      try {
        final apiUrl = dotenv.env['API_URL'] ?? '';
        final endpoint = '$apiUrl/user/history/$_userId';

        final response = await http.get(Uri.parse(endpoint));

        if (response.statusCode == 200) {
          List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
          final historyList = data.map((item) => item as Map<String, dynamic>).toList();

          // Save to Isar
          await _saveToLocalStorage(historyList);
          if (!mounted) return;
          setState(() {
            travelHistory = historyList;
          });
        } else {
          log('Error fetching travel history from API: ${response.statusCode}');
          await _loadFromLocalStorage();
        }
      } catch (e) {
        log('Error fetching travel history from API: $e');
        await _loadFromLocalStorage();
      }
    }

    _isLoading = false;
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _saveToLocalStorage(List<Map<String, dynamic>> historyList) async {
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

      travelHistory = localHistory
          .map((history) => {
                'route_number': history.routeNumber,
                'date': history.date?.toIso8601String(),
              })
          .toList();

      if (!mounted) return;
      setState(() {});
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
              _isLoading ? const Center(child: CircularProgressIndicator()) : _buildTravelHistory(),
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
            onExpansionChanged: (expanded) {
              if (!expanded) {
                _fetchTravelHistory();
              }
            },
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
                physics: const NeverScrollableScrollPhysics(), // no inner scrolling
                itemCount: travelHistory.length,
                itemBuilder: (context, index) {
                  final travel = travelHistory[index];
                  final routeNumber = travel['route_number'] ?? 'Unknown Route';
                  final rawDate = travel['date'] ?? '';

                  DateTime? travelDate;
                  String formattedDate = 'Unknown Date';

                  try {
                    travelDate = DateTime.parse(rawDate);
                    formattedDate = DateFormat('MMM dd, yyyy - HH:mm').format(travelDate);
                  } catch (e) {
                    log('Error parsing date: $e');
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 1,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
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
