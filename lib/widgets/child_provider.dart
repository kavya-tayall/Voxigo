import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:convert';
import 'package:test_app/child_pages/music_page.dart';



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

  Future<String?> fetchJson(String jsonName) async{
    FirebaseStorage storage = FirebaseStorage.instance;
    Reference ref = storage.ref().child('user_folders/${childData!['username']}/$jsonName');


    final data = await ref.getData();
    if (data!= null){
      String jsonString = String.fromCharCodes(data);
      print('Fetched JSON: $jsonString');
      return jsonString;
    } else{
      print("data not found");
      return null;
    }
  }

  Future<void> changeMusicJson(List<Song> info) async{
    try {
      List<Map<String, dynamic>> songListJson = info.map((song) => song.toJson()).toList();

      String jsonData = json.encode(songListJson);

      final directory = Directory.systemTemp;
      File tempFile = File('${directory.path}/temp.json');
      await tempFile.writeAsString(jsonData);

      Reference ref = FirebaseStorage.instance.ref('user_folders/${childData!['username']}/music.json');
      final SettableMetadata metadata = SettableMetadata(contentType: 'application/json',);

      UploadTask uploadTask = ref.putFile(tempFile, metadata);
      TaskSnapshot snapshot = await uploadTask;


      print("Songs uploaded to Firebase successfully.");
    } catch (e) {
      print("Error uploading songs: $e");
    }


  }

  Future<void> changeGridJson(Map<String, List> info) async{
    try {
      String jsonData = json.encode(info);

      final directory = Directory.systemTemp;
      File tempFile = File('${directory.path}/tempGrid.json');
      await tempFile.writeAsString(jsonData);

      Reference ref = FirebaseStorage.instance.ref('user_folders/${childData!['username']}/board.json');
      final SettableMetadata metadata = SettableMetadata(contentType: 'application/json',);

      UploadTask uploadTask = ref.putFile(tempFile, metadata);
      TaskSnapshot snapshot = await uploadTask;

      print("Board uploaded to Firebase successfully.");
    } catch (e) {
      print("Error uploading songs: $e");
    }
  }

  Future<String> fetchChildButtonsData() async {
    try {
      DocumentSnapshot childSnapshot = await FirebaseFirestore.instance
          .collection('children')
          .doc(childId)
          .get();

      if (childSnapshot.exists) {
        Map<String, dynamic>? childData = childSnapshot.data() as Map<String, dynamic>?;
        if (childData != null &&
            childData['data'] != null &&
            childData['data']['selectedButtons'] != null) {
          List<dynamic> allButtons = childData['data']['selectedButtons'];
          for (int i = 0; i < allButtons.length; i++) {
            allButtons[i]['timestamp'] = allButtons[i]['timestamp'].toDate();
          }
          print(allButtons);
          var stringList = allButtons.join(", ");
          print(stringList);
          return stringList;

        } else {
          print("no data");
          return "no data";
        }
      } else{
        print("dont work");
        return ("dont work");
      }


    } catch (e) {
      print('Error fetching selected buttons: $e');
      return "error";
    }
  }

  Future<String> fetchChildFeelingsData() async {
    try {
      DocumentSnapshot childSnapshot = await FirebaseFirestore.instance
          .collection('children')
          .doc(childId)
          .get();

      if (childSnapshot.exists) {
        Map<String, dynamic>? childData = childSnapshot.data() as Map<String, dynamic>?;
        if (childData != null &&
            childData['data'] != null &&
            childData['data']['selectedFeelings'] != null) {
          List<dynamic> allFeelings = childData['data']['selectedFeelings'];
          for (int i = 0; i < allFeelings.length; i++) {
            allFeelings[i]['timestamp'] = allFeelings[i]['timestamp'].toDate();
          }
          var stringList = allFeelings.join(", ");
          return stringList;

        } else {
          print("no data");
          return "no data";
        }
      } else{
        print("dont work");
        return ("dont work");
      }


    } catch (e) {
      print('Error fetching selected buttons: $e');
      return "error";
    }
  }

  void logout() {
    childId = null;
    childData = null;
    notifyListeners();
  }
}