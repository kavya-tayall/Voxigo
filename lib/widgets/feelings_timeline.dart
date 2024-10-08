import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timelines_plus/timelines_plus.dart';


class FeelingsTimeline extends StatefulWidget {
  final String searchText;

  FeelingsTimeline({required this.searchText});

  @override
  FeelingsTimelineState createState() => FeelingsTimelineState();
}

class FeelingsTimelineState extends State<FeelingsTimeline> {
  List<Map<String, dynamic>> selectedFeelings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchChildSelectedFeelings();
  }

  Future<void> fetchChildSelectedFeelings() async {
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
                    childData['data']['selectedFeelings'] != null) {
                  setState(() {
                    selectedFeelings = childData['data']['selectedFeelings'];
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



  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (selectedFeelings.isEmpty) {
      return Center(child: Text('No feelings selected yet'));
    }

    //List<MapEntry<String, int>> sortedButtons = buttonCounts.entries.toList()
    //  ..sort((a, b) => b.value.compareTo(a.value));

   /* sortedButtons = sortedButtons
        .where((entry) =>
        entry.key.toLowerCase().contains(widget.searchText.toLowerCase()))
        .toList();

    */

    return Placeholder();
  }
}