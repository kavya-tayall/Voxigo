import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:test_app/child_pages/music_page.dart';



class ChildProvider with ChangeNotifier {
  Map<String, dynamic>? childData;
  String? childId;

  void setChildData(String childId, Map<String, dynamic> data) {
    this.childId = childId;
    childData = data;
    notifyListeners();
  }

  Future<String> _uploadFile(_selectedImage) async {
    try {
      // Create a unique file name
      String fileName = '${DateTime.now().millisecondsSinceEpoch}_${_selectedImage!.path.split('/').last}';

      // Create a reference to Firebase Storage
      Reference storageRef = FirebaseStorage.instance.ref().child('uploads/$fileName');

      // Upload the file
      UploadTask uploadTask = storageRef.putFile(_selectedImage!);

      // Wait for the upload to complete
      TaskSnapshot snapshot = await uploadTask;

      // Get the download URL
      String downloadURL = await snapshot.ref.getDownloadURL();

      // Save the reference to Firestore
      await FirebaseFirestore.instance.collection('children').doc(childId).update({
        'imageUrl': downloadURL,
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      return downloadURL;
    } catch (e) {
      // Handle errors
      print('Error uploading file: $e');
      return "error " "$e";
    }
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
    print(childData);
    Reference ref = storage.ref().child('user_folders/${childData!['username']}/$jsonName');

    print("ch1");

    print(ref.fullPath);
    final data = await ref.getData();
    print("ch2");
    if (data!= null){
      String jsonString = String.fromCharCodes(data);
      print(jsonString);
      print('Fetched JSON: $jsonString');
      return jsonString;
    } else{
      print("data not found");
      return null;
    }
  }

  Future<void> changeMusicJson(List<Song> info) async{
    try {
      // Convert List<Song> to List<Map<String, dynamic>>
      List<Map<String, dynamic>> songListJson = info.map((song) => song.toJson()).toList();

      // Convert the List<Map<String, dynamic>> to JSON string
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
      // Convert List<Song> to List<Map<String, dynamic>>
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

  void logout() {
    childId = null;
    childData = null;
    notifyListeners();
  }
}
