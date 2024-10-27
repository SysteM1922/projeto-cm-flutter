import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import 'package:projeto_cm_flutter/screens/map_screen.dart';
import 'package:projeto_cm_flutter/screens/scan_qr_code_screen.dart';
import 'package:projeto_cm_flutter/screens/nfc_screen.dart';
import 'package:projeto_cm_flutter/screens/user_screen.dart';
import 'package:projeto_cm_flutter/services/database_service.dart';
import 'package:projeto_cm_flutter/state/app_state.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with SingleTickerProviderStateMixin {
  late StreamSubscription<List<ConnectivityResult>>
      _connectionServiceStatusStream;
  final DatabaseService dbService = DatabaseService.getInstance();

  bool? _isUpdatingDataBase;
  bool _internetModal = false;
  final Icon _wifiIcon = Icon(Icons.wifi_off, color: Colors.red);

  late TabController _tabController;

  bool _isTabControllerInitialized = false;

  @override
  void initState() {
    super.initState();
    _listenToConnectionServiceStatus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      _tabController = TabController(
        length: 4,
        vsync: this,
        initialIndex: appState.selectedTab,
      );

      _tabController.addListener(() {
        if (_tabController.indexIsChanging) {
          appState.setSelectedTab(_tabController.index);
        }
      });

      setState(() {
        _isTabControllerInitialized = true;
      });
    });
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
    _connectionServiceStatusStream = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) async {
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
      _checkDataBaseStatus().then((_) {
        if (!mounted) return;
        setState(() {
          _isUpdatingDataBase = false;
          _internetModal = false;
        });
      });
    });
  }

  Future<void> _checkDataBaseStatus() async {
    int status = await dbService.isDatabaseUpdated();
    if (status == 404) {
      setState(() {
        _isUpdatingDataBase = true;
      });
      await dbService.updateDatabase();
    } else if (status == 500) {
      _showConnectionDialog(
          "An error occurred while checking the database status. Please check your internet connection.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (!_isTabControllerInitialized) {
          // TabController not initialized yet
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If AppState.selectedTab has changed externally, update TabController
        if (_tabController.index != appState.selectedTab &&
            !_tabController.indexIsChanging) {
          _tabController.animateTo(appState.selectedTab);
        }

        return Scaffold(
          body: Stack(
            children: [
              TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: <Widget>[
                  MapScreen(
                    stopId: appState.centerStopId,
                    isUpdatingDataBase: _isUpdatingDataBase,
                  ),
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
                    onPressed: () {},
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
                    content: const Text(
                        'The database is outdated. Wait while we update it.'),
                    actions: <Widget>[
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
          bottomNavigationBar: TabBar(
            controller: _tabController,
            labelColor: Colors.blue[800],
            unselectedLabelColor: Colors.grey,
            overlayColor:
                MaterialStateProperty.all(Colors.grey.withOpacity(0.1)),
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
        );
      },
    );
  }
}
