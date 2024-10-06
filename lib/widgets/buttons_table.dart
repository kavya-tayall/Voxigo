
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'buttons_screen.dart';

class ButtonsTable extends StatefulWidget {
  final String searchText;

  ButtonsTable({required this.searchText});

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

  void _navigateToButtonDetails(String buttonText, List<dynamic> buttonInstances) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ButtonDetailsScreen(buttonText: buttonText, buttonInstances: buttonInstances),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (selectedButtons.isEmpty) {
      return Center(child: Text('No buttons selected yet'));
    }

    List<MapEntry<String, int>> sortedButtons = buttonCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    sortedButtons = sortedButtons
        .where((entry) =>
        entry.key.toLowerCase().contains(widget.searchText.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: sortedButtons.length,
      itemBuilder: (context, index) {
        String text = sortedButtons[index].key;
        int quantity = sortedButtons[index].value;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: TextButton(
                        onPressed: () {

                          List<dynamic> buttonInstances = selectedButtons
                              .where((button) => button['text'] == text)
                              .toList();
                          _navigateToButtonDetails(text, buttonInstances);
                        },
                        child: Text(
                          'See More',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Text(
                        'Quantity',
                        style: TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        quantity.toString(),
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}