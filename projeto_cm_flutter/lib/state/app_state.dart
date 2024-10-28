import 'package:flutter/material.dart';

class AppState with ChangeNotifier {
  int _selectedTab = 0;
  String? _centerStopId;
  bool _connectionStatus = false;

  int get selectedTab => _selectedTab;
  String? get centerStopId => _centerStopId;
  bool get connectionStatus => _connectionStatus;

  void navigateToMapWithStop(String stopId) {
    _centerStopId = stopId;
    _selectedTab = 0; // Map is the first tab
    notifyListeners();
  }

  void setSelectedTab(int index) {
    _selectedTab = index;
    notifyListeners();
  }

  void resetCenterStopId() {
    _centerStopId = null;
    notifyListeners();
  }

  void setConnectionStatus(bool status) {
    _connectionStatus = status;
    notifyListeners();
  }
}