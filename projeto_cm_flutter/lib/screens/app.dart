import 'package:flutter/material.dart';

import 'package:projeto_cm_flutter/screens/map_screen.dart';
import 'package:projeto_cm_flutter/screens/scan_qr_code_screen.dart';
import 'package:projeto_cm_flutter/screens/nfc_screen.dart';
import 'package:projeto_cm_flutter/screens/user_screen.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  String currentPage = 'home';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      animationDuration: const Duration(milliseconds: 0),
      length: 4,
      initialIndex: 0,
      child: Scaffold(
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: <Widget>[
            BusTrackingScreen(),
            ScanQRCodeScreen(),
            NFCScreen(),
            UserScreen(),
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
                text: 'QR Reader',
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
