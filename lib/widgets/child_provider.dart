import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChildProvider with ChangeNotifier {
  Map<String, dynamic>? childData;
  String? childId;

  void setChildData(String childId, Map<String, dynamic> data) {
    this.childId = childId;
    childData = data;
    notifyListeners();
  }

  Future<void> addSelectedButton(String text, Timestamp timestamp) async {
    if (childId != null) {
      await FirebaseFirestore.instance.collection('children').doc(childId).update({
        'data.selectedButtons': FieldValue.arrayUnion([{
          'text': text,
          'timestamp': timestamp
        }])
      });
    } else {
      throw Exception("No child logged in");
    }
  }

  Future<void> addSelectedFeelings(String text, Timestamp timestamp) async {
    if (childId != null) {
      await FirebaseFirestore.instance.collection('children').doc(childId).update({
        'data.selectedFeelings': FieldValue.arrayUnion([{
          'text': text,
          'timestamp': timestamp
        }])
      });
    } else {
      throw Exception("No child logged in");
    }
  }

  void logout() {
    childId = null;
    childData = null;
    notifyListeners();
  }

}
