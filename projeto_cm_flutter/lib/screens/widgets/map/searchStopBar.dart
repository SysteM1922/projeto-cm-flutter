import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:projeto_cm_flutter/services/database_service.dart';
import 'package:projeto_cm_flutter/isar/models.dart' as models;

class SearchStopBar extends StatefulWidget {
  const SearchStopBar({super.key, required this.markerTapped});

  final Function(models.Stop) markerTapped;

  @override
  _SearchStopBarState createState() => _SearchStopBarState();
}

class _SearchStopBarState extends State<SearchStopBar> {
  final DatabaseService dbService = DatabaseService.getInstance();
  List<String> _searchResults = [];
  late TextEditingController _searchController;

  final Map<String, dynamic> _nameToData = {}; // JUST STOPS

  @override
  void initState() {
    super.initState();

    _searchController = TextEditingController();

    _fetchStopAndBusNames();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _markerTapped(models.Stop stop) {
    widget.markerTapped(stop);
  }

  Future<void> _fetchStopAndBusNames() async {
    final List<models.Stop> stops = await dbService.getAllStops();

    for (var stop in stops) {
      _nameToData[utf8.decode(stop.stopName!.codeUnits)] = stop;
    }

    setState(() {});
  }

  void _handleResultSelection(String result) {
    // Close keyboard
    FocusScope.of(context).unfocus();

    // Access the data associated with the selected name
    final selectedData = _nameToData[result];

    if (selectedData is models.Stop) {
      // Handle stop selection
      _markerTapped(selectedData);
    }

    // Clear search results
    _searchController.clear();
    _searchResults.clear();
    setState(() {});
  }

  void _handleSearch() {
    String searchText = _searchController.text.toLowerCase();
    _searchResults.clear();
    _nameToData.forEach((name, data) {
      if (name.toLowerCase().contains(searchText)) {
        _searchResults.add(name);
      }
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            SizedBox(height: 20),
            Visibility(
              visible: _searchResults.isNotEmpty &&
                  _searchController.text.isNotEmpty &&
                  FocusScope.of(context).hasFocus,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20.0),
                      bottomRight: Radius.circular(20.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: _searchResults.length > 3
                      ? SizedBox(
                          height: 300, // Adjust the height as needed
                          child: Scrollbar(
                            thickness: 4.0,
                            child: ListView.builder(
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(_searchResults[index]),
                                  subtitle: Text("Tap to see more",
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 12)),
                                  onTap: () {
                                    _handleResultSelection(
                                        _searchResults[index]);
                                  },
                                );
                              },
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(_searchResults[index]),
                              subtitle: Text("Tap to see more",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                              onTap: () {
                                _handleResultSelection(_searchResults[index]);
                              },
                            );
                          },
                        ),
                ),
              ),
            ),
          ],
        ),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _handleSearch();
              },
              decoration: InputDecoration(
                hintText: "Search for stops...",
                floatingLabelBehavior: FloatingLabelBehavior.never,
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _searchResults.clear();
                          setState(() {});
                        },
                        icon: Icon(Icons.close, color: Colors.grey[600]))
                    : null,
              ),
              textAlignVertical: TextAlignVertical.center,
            ),
          ),
        ),
      ],
    );
  }
}
