import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:projeto_cm_flutter/screens/map_screen.dart';
import 'package:projeto_cm_flutter/screens/scan_qr_code_screen.dart';
import 'package:projeto_cm_flutter/screens/nfc_screen.dart';
import 'package:projeto_cm_flutter/screens/user_screen.dart';
import 'package:projeto_cm_flutter/services/database_service.dart';
import 'package:projeto_cm_flutter/state/app_state.dart';
import 'package:provider/provider.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with SingleTickerProviderStateMixin {
  late StreamSubscription<List<ConnectivityResult>> _connectionServiceStatusStream;
  final DatabaseService dbService = DatabaseService.getInstance();

  static bool? _isUpdatingDataBase;
  bool _internetModal = false;

  final Icon _wifiIcon = Icon(Icons.wifi_off, color: Colors.red);

  late TabController _tabController;

  bool _isTabControllerInitialized = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      _tabController = TabController(
        animationDuration: const Duration(milliseconds: 200),
        length: 4,
        vsync: this,
        initialIndex: appState.selectedTab,
      );

      _tabController.addListener(() {
        if (_tabController.indexIsChanging) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            appState.setSelectedTab(_tabController.index);
          });
        }
      });

      setState(() {
        _isTabControllerInitialized = true;
      });
    });
    
    _listenToConnectionServiceStatus();
  }

  @override
  void dispose() {
    _connectionServiceStatusStream.cancel();
    if (_isTabControllerInitialized) {
      _tabController.dispose();
    }
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
    _connectionServiceStatusStream = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) async {
      if (!result.contains(ConnectivityResult.wifi) &&
          !result.contains(ConnectivityResult.mobile) &&
          !result.contains(ConnectivityResult.ethernet) &&
          !result.contains(ConnectivityResult.vpn)) {
        if (!_internetModal) {
          _showConnectionDialog("You are offline. Using offline data. Please check your internet connection.");
          _internetModal = true;
        }
        _isUpdatingDataBase = false;
        if (!mounted) return;
        setState(() {});
        return;
      }
      await _checkDataBaseStatus();
      _isUpdatingDataBase = false;
      _internetModal = false;
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<void> _checkDataBaseStatus() async {
    int status = await dbService.isDatabaseUpdated();
    if (status == 404) {
      _isUpdatingDataBase = true;
      if (!mounted) return;
      setState(() {});
      await dbService.updateDatabase();
      return;
    } else if (status == 500) {
      _showConnectionDialog("An error occurred while checking the database status. Please check your internet connection.");
    }
    _isUpdatingDataBase = false;
    if (!mounted) return;
    setState(() {});
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, appState, child) {
      if (!_isTabControllerInitialized) {
        return Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      // If AppState.selectedTab has changed externally, update TabController
      if (_tabController.index != appState.selectedTab && !_tabController.indexIsChanging) {
        _tabController.animateTo(appState.selectedTab);
      }

      return Scaffold(
        body: Stack(
          children: [
            TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: <Widget>[
                MapScreen(stopId: appState.centerStopId, isUpdatingDataBase: _isUpdatingDataBase),
                const ScanQRCodeScreen(),
                const NFCScreen(),
                const UserScreen(),
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
            if (_isUpdatingDataBase != null && _isUpdatingDataBase!)
              Container(
                color: Colors.black45,
                child: AlertDialog(
                  title: const Text('Database Update'),
                  content: const Text('The database is outdated. Wait while we update it.'),
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
            controller: _tabController,
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
      );
    });
  }
}
