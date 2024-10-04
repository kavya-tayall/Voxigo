import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:collection';

class ButtonsTable extends StatefulWidget {
  @override
  ButtonsTableState createState() => ButtonsTableState();
}

class ButtonsTableState extends State<ButtonsTable> {
  List<dynamic> selectedButtons = [];
  bool isLoading = true;
  Map<String, int> buttonCounts = {};

  @override
  void initState() {
    super.initState();
    fetchChildSelectedButtons();
  }

  Future<void> fetchChildSelectedButtons() async {
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
            List<String> childrenIds = List<String>.from(parentData['children']);

            if (childrenIds.isNotEmpty) {
              String childId = childrenIds[0]; // Select a specific child

              DocumentSnapshot childSnapshot = await FirebaseFirestore.instance
                  .collection('children')
                  .doc(childId)
                  .get();

              if (childSnapshot.exists) {
                Map<String, dynamic>? childData = childSnapshot.data() as Map<String, dynamic>?;
                if (childData != null &&
                    childData['data'] != null &&
                    childData['data']['selectedButtons'] != null) {
                  setState(() {
                    selectedButtons = childData['data']['selectedButtons'];
                    _calculateButtonCounts();
                    isLoading = false;
                  });
                }
              } else {
                setState(() {
                  isLoading = false;
                });
                print('Child document does not exist');
              }
            }
          } else {
            setState(() {
              isLoading = false;
            });
            print('Parent does not have any children listed');
          }
        } else {
          setState(() {
            isLoading = false;
          });
          print('Parent document does not exist');
        }
      } else {
        setState(() {
          isLoading = false;
        });
        print('No authenticated user');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching selected buttons: $e');
    }
  }

  void _calculateButtonCounts() {
    buttonCounts.clear();
    for (var button in selectedButtons) {
      String text = button['text'];
      if (buttonCounts.containsKey(text)) {
        buttonCounts[text] = buttonCounts[text]! + 1;
      } else {
        buttonCounts[text] = 1;
      }
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime now = DateTime.now();
    DateTime date = timestamp.toDate();
    Duration difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return DateFormat('EEE, MMM d').format(date);
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (selectedButtons.isEmpty) {
      return Center(child: Text('No buttons selected yet'));
    }

    Map<String, Timestamp> latestTimestamps = {};


    for (var button in selectedButtons) {
      String text = button['text'];
      Timestamp timestamp = button['timestamp'];

      if (!latestTimestamps.containsKey(text) || timestamp.compareTo(latestTimestamps[text]!) > 0) {
        latestTimestamps[text] = timestamp;
      }
    }


    List<MapEntry<String, Timestamp>> sortedButtons = latestTimestamps.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          border: TableBorder.all(
            color: Colors.grey,
            width: 1,
          ),
          columns: const <DataColumn>[
            DataColumn(
              label: Text(
                'Button Text',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Timestamp',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Quantity',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: sortedButtons.map((entry) {
            String text = entry.key;
            Timestamp timestamp = entry.value;
            String formattedTimestamp = _formatTimestamp(timestamp);
            int quantity = buttonCounts[text] ?? 1;

            return DataRow(cells: <DataCell>[
              DataCell(Text(text)),
              DataCell(Text(formattedTimestamp)),
              DataCell(Text(quantity.toString())),
            ]);
          }).toList(),
        ),
      ),
    );
  }

}
