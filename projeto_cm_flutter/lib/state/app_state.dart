import 'package:flutter/material.dart';

class AppState with ChangeNotifier {
  int _selectedTab = 0;
  String? _centerStopId;

  int get selectedTab => _selectedTab;
  String? get centerStopId => _centerStopId;

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
}