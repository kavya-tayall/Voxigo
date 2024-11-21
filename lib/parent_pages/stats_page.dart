import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../child_pages/home_page.dart';
import '../widgets/buttons_table.dart';
import '../widgets/feelings_timeline.dart';

class StatsPage extends StatefulWidget {
  @override
  _StatsPageState createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> with SingleTickerProviderStateMixin {
  String searchText = '';
  String selectedTimeFilter = 'Today';
  DateTimeRange? customDateRange;
  String? selectedChildId;
  Map<String, String> childIdToUsername = {};
  bool isLoading = true;
  List<dynamic> selectedButtons = [];
  List<dynamic> selectedFeelings = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    fetchChildren();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTimeRange? _getDateRange(String filter) {
    DateTime now = DateTime.now();
    DateTime start;
    DateTime end = now;

    if (filter == 'Today') {
      start = DateTime(now.year, now.month, now.day);
    } else if (filter == 'This Week') {
      start = now.subtract(Duration(days: now.weekday - 1));
    } else if (filter == 'This Month') {
      start = DateTime(now.year, now.month, 1);
    } else if (filter == 'Custom' && customDateRange != null) {
      return customDateRange;
    } else {
      return null;
    }
    return DateTimeRange(start: start, end: end);
  }

  Future<void> _pickCustomDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: customDateRange ??
          DateTimeRange(start: DateTime.now().subtract(Duration(days: 7)), end: DateTime.now()),
    );
    if (picked != null) {
      setState(() {
        customDateRange = picked;
        selectedTimeFilter = 'Custom';
        fetchDataForCurrentTab();
      });
    }
  }

  Future<void> fetchChildren() async {
    setState(() => isLoading = true);
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot parentSnapshot = await FirebaseFirestore.instance
            .collection('parents')
            .doc(currentUser.uid)
            .get();

        if (parentSnapshot.exists) {
          List<String> childIds = List<String>.from(parentSnapshot['children']);
          for (String childId in childIds) {
            DocumentSnapshot childSnapshot = await FirebaseFirestore.instance
                .collection('children')
                .doc(childId)
                .get();
            if (childSnapshot.exists) {
              childIdToUsername[childId] = childSnapshot['username'];
            }
          }
          setState(() {
            selectedChildId = childIds.isNotEmpty ? childIds[0] : null;
            fetchDataForCurrentTab();
          });
        }
      }
    } catch (e) {
      print('Error fetching children: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchDataForCurrentTab() async {
    if (selectedChildId == null) return;
    setState(() => isLoading = true);

    try {
      DocumentSnapshot childSnapshot = await FirebaseFirestore.instance
          .collection('children')
          .doc(selectedChildId)
          .get();

      if (childSnapshot.exists) {
        Map<String, dynamic> childData = childSnapshot['data'];

        List<dynamic> items = (_tabController.index == 0)
            ? childData['selectedButtons']
            : childData['selectedFeelings'];

        List<dynamic> filteredItems = items.where((item) {
          Timestamp timestamp = item['timestamp'];
          DateTime itemDate = timestamp.toDate();
          DateTimeRange? range = _getDateRange(selectedTimeFilter);
          if (range != null) {
            DateTime adjustedEnd = range.end.add(Duration(hours: 23, minutes: 59, seconds: 59));
            return itemDate.isAfter(range.start) && itemDate.isBefore(adjustedEnd);
          }
          return true;
        }).toList();

        setState(() {
          if (_tabController.index == 0) {
            selectedButtons = filteredItems;
          } else {
            selectedFeelings = filteredItems;
          }
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 4,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, color: Colors.black, size: 30),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3.0),
                  child: Image.asset("assets/imgs/logo_without_text.png", width: 60),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: GradientText(
                    "MindBridge",
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.blueAccent, Colors.deepPurpleAccent],
                    ),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(80.0),
          child: Column(
            children: [
              Container(
                color: Colors.grey[300],
                child: TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: 'Button Stats'),
                    Tab(text: 'Feeling Stats'),
                  ],
                  indicatorColor: Colors.blueAccent,
                  indicatorWeight: 3,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey[600],
                  labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatsContent('Buttons Table', selectedButtons),
          _buildStatsContent('Feelings Table', selectedFeelings),
        ],
      ),

    );
  }


  Widget _buildStatsContent(String label, List<dynamic> items) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedChildId,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedChildId = newValue!;
                          fetchDataForCurrentTab();
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Select Child',
                        border: OutlineInputBorder(),
                      ),
                      items: childIdToUsername.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Search',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchText = value.toLowerCase();
                          fetchDataForCurrentTab();
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 5),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: selectedTimeFilter,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedTimeFilter = newValue!;
                          if (newValue == 'Custom') {
                            _pickCustomDateRange();
                          } else {
                            fetchDataForCurrentTab();
                          }
                        });
                      },
                      decoration: InputDecoration(border: OutlineInputBorder()),
                      items: ['Today', 'This Week', 'This Month', 'All Time', 'Custom']
                          .map((filter) => DropdownMenuItem(
                        value: filter,
                        child: Text(filter),
                      ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: label == 'Buttons Table'
              ? ButtonsTable(
            searchText: searchText,
            selectedButtons: selectedButtons,
            isLoading: isLoading,
          )
              : FeelingsTable(
            searchText: searchText,
            selectedFeelings: selectedFeelings,
            isLoading: isLoading,
          ),
        ),
      ],
    );
  }
}