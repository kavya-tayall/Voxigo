import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/feelings_timeline.dart';

class FeelingsStatsPage extends StatefulWidget {
  @override
  FeelingsStatsPageState createState() => FeelingsStatsPageState();
}

class FeelingsStatsPageState extends State<FeelingsStatsPage> with SingleTickerProviderStateMixin {
  String searchText = '';
  String selectedTimeFilter = 'Today';
  DateTimeRange? customDateRange;
  List<dynamic> selectedFeelings = [];
  Map<String, String> childIdToUsername = {};
  String? selectedChildId;
  bool isLoading = true;

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
      int weekDay = now.weekday;
      start = now.subtract(Duration(days: weekDay - 1));
    } else if (filter == 'This Month') {
      start = DateTime(now.year, now.month, 1);
    } else if (filter == 'Custom' && customDateRange != null) {
      return customDateRange;
    } else if (filter == 'All Time') {
      return null;
    } else {
      return null;
    }

    return DateTimeRange(start: start, end: end);
  }

  void _pickCustomDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: customDateRange ?? DateTimeRange(
        start: DateTime.now().subtract(Duration(days: 7)),
        end: DateTime.now(),
      ),
    );

    if (picked != null) {
      setState(() {
        customDateRange = picked;
        selectedTimeFilter = 'Custom';
        fetchChildSelectedFeelings();
      });
    }
  }

  Future<void> fetchChildren() async {
    setState(() {
      isLoading = true;
    });
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        String parentId = currentUser.uid;

        DocumentSnapshot parentSnapshot = await FirebaseFirestore.instance
            .collection('parents')
            .doc(parentId)
            .get();

        if (parentSnapshot.exists) {
          Map<String, dynamic>? parentData = parentSnapshot.data() as Map<String, dynamic>?;
          if (parentData != null && parentData['children'] != null) {
            List<String> childIds = List<String>.from(parentData['children']);


            for (String childId in childIds) {
              DocumentSnapshot childSnapshot = await FirebaseFirestore.instance
                  .collection('children')
                  .doc(childId)
                  .get();

              if (childSnapshot.exists) {
                Map<String, dynamic>? childData = childSnapshot.data() as Map<String, dynamic>?;
                if (childData != null && childData['username'] != null) {

                  childIdToUsername[childId] = childData['username'];
                }
              }
            }

            setState(() {
              selectedChildId = childIds.isNotEmpty ? childIds[0] : null;
              fetchChildSelectedFeelings();
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching children: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchChildSelectedFeelings() async {
    if (selectedChildId == null) return;

    setState(() {
      isLoading = true;
    });
    try {
      DocumentSnapshot childSnapshot = await FirebaseFirestore.instance
          .collection('children')
          .doc(selectedChildId)
          .get();

      if (childSnapshot.exists) {
        Map<String, dynamic>? childData = childSnapshot.data() as Map<String, dynamic>?;
        if (childData != null && childData['data'] != null && childData['data']['selectedFeelings'] != null) {
          List<dynamic> allFeelings = childData['data']['selectedFeelings'];
          List<dynamic> filteredFeelings = allFeelings.where((feeling) {
            Timestamp timestamp = feeling['timestamp'];
            DateTime feelingDate = timestamp.toDate();

            if (_getDateRange(selectedTimeFilter) != null) {
              DateTime adjustedEndDate = _getDateRange(selectedTimeFilter)!.end.add(Duration(hours: 23, minutes: 59, seconds: 59));
              return (feelingDate.isAtSameMomentAs(_getDateRange(selectedTimeFilter)!.start) || feelingDate.isAfter(_getDateRange(selectedTimeFilter)!.start)) &&
                  (feelingDate.isAtSameMomentAs(adjustedEndDate) || feelingDate.isBefore(adjustedEndDate));
            }
            return true;
          }).toList();

          setState(() {
            selectedFeelings = filteredFeelings;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching selected feelings: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Feeling Stats'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Feelings Table'),
            Tab(text: 'AI Page'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Column(
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
                            onChanged: (String? newValue) async {
                              selectedChildId = newValue!;
                              await fetchChildSelectedFeelings();
                              setState(() {});
                            },
                            decoration: InputDecoration(
                              labelText: 'Select Child',
                              border: OutlineInputBorder(),
                            ),
                            items: childIdToUsername.entries.map<DropdownMenuItem<String>>((entry) {
                              return DropdownMenuItem<String>(
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
                            onChanged: (value) async {
                              searchText = value.toLowerCase();
                              await fetchChildSelectedFeelings();
                              setState(() {});
                            },
                          ),
                        ),
                        SizedBox(width: 5),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            value: selectedTimeFilter,
                            onChanged: (String? newValue) async {
                              selectedTimeFilter = newValue!;
                              if (selectedTimeFilter == 'Custom') {
                                _pickCustomDateRange();
                              } else {
                                await fetchChildSelectedFeelings();
                              }
                              setState(() {});
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            items: <String>['Today', 'This Week', 'This Month', 'All Time', 'Custom']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: FeelingsTable(
                    searchText: searchText,
                    selectedFeelings: selectedFeelings,
                    isLoading: isLoading,
                  ),
                ),
              ),
            ],
          ),
          Center(
            child: Text(
              'hi ai ',
              style: TextStyle(fontSize: 24),
            ),
          ),
        ],
      ),
    );
  }
}
