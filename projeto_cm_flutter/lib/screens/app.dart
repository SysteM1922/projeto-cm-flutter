import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:projeto_cm_flutter/screens/map_screen.dart';
import 'package:projeto_cm_flutter/screens/scan_qr_code_screen.dart';
import 'package:projeto_cm_flutter/screens/nfc_screen.dart';
import 'package:projeto_cm_flutter/screens/user_screen.dart';
import 'package:projeto_cm_flutter/services/database_service.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late StreamSubscription<List<ConnectivityResult>>
      _connectionServiceStatusStream;
  final DatabaseService dbService = DatabaseService();

  bool _isUpdatingDataBase = false;
  bool _internetModal = false;
  bool _isInitialized = false;

  final Icon _wifiIcon = Icon(Icons.wifi_off, color: Colors.red);

   @override
  void initState() {
    super.initState();
    _initialize();
    _listenToConnectionServiceStatus();
  }

  Future<void> _initialize() async {
    await dbService.initialize();
    
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _connectionServiceStatusStream.cancel();
    super.dispose();
  }

  void _showConnectionDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Internet Connection Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Ok', style: TextStyle(color: Colors.blue[800])),
            ),
          ],
        );
      },
    );
  }

  void _listenToConnectionServiceStatus() async {
    _connectionServiceStatusStream = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      if (!result.contains(ConnectivityResult.wifi) &&
          !result.contains(ConnectivityResult.mobile) &&
          !result.contains(ConnectivityResult.ethernet) &&
          !result.contains(ConnectivityResult.vpn)) {
        if (!_internetModal) {
          _showConnectionDialog(
              "You are offline. Using offline data. Please check your internet connection.");
          _internetModal = true;
        }
        if (!mounted) {
          return;
        }
        setState(() {});
        return;
      }
      _checkDataBaseStatus();
      if (!mounted) {
        return;
      }
      setState(() {
        _internetModal = false;
      });
    });
  }

  void _checkDataBaseStatus() async {
    int status = await dbService.isDatabaseUpdated();
    if (status == 404) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isUpdatingDataBase = true;
      });
      dbService.updateDatabase( () {
        if (!mounted) {
          return;
        }
        setState(() {
          _isUpdatingDataBase = false;
        });
      });
    } else if (status == 500) {
      _showConnectionDialog(
          "An error occurred while checking the database status. Please check your internet connection.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      animationDuration: const Duration(milliseconds: 0),
      length: 4,
      initialIndex: 0,
      child: Scaffold(
        body: Stack(
          children: [
            const TabBarView(
              physics: NeverScrollableScrollPhysics(),
              children: <Widget>[
                BusTrackingScreen(),
                ScanQRCodeScreen(),
                NFCScreen(),
                UserScreen(),
              ],
            ),
            if (_internetModal)
              Positioned(
                bottom: 20,
                left: 10,
                child: ElevatedButton(
                  onPressed: () => {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.all(20),
                  ),
                  child: _wifiIcon,
                ),
              ),
            if (_isUpdatingDataBase)
              Container(
                color: Colors.black45,
                child: AlertDialog(
                  title: const Text('Database Update'),
                  content: const Text(
                      'The database is outdated. Wait while we update it.'),
                  actions: <Widget>[
                    // add loading spinner
                    Center(
                      child: CircularProgressIndicator(
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          color: Colors.white,
          padding: const EdgeInsets.only(top: 10.0),
          height: 80.0,
          child: TabBar(
            labelColor: Colors.blue[800],
            unselectedLabelColor: Colors.grey,
            overlayColor: WidgetStateProperty.all(Colors.grey.withOpacity(0.1)),
            splashBorderRadius: BorderRadius.circular(20.0),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            dividerHeight: 0.0,
            indicatorPadding: const EdgeInsets.fromLTRB(30, 0, 30, 28),
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              color: Colors.blue[50],
            ),
            tabs: <Widget>[
              Tab(
                icon: Icon(Icons.map),
                text: 'Map',
                iconMargin: EdgeInsets.only(bottom: 5.0),
              ),
              Tab(
                icon: Icon(Icons.qr_code),
                text: 'Scan QR',
                iconMargin: EdgeInsets.only(bottom: 5.0),
              ),
              Tab(
                icon: Icon(Icons.credit_card),
                text: 'Card',
                iconMargin: EdgeInsets.only(bottom: 5.0),
              ),
              Tab(
                icon: Icon(Icons.person),
                text: 'User',
                iconMargin: EdgeInsets.only(bottom: 5.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
