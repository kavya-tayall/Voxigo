import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:convert';
import 'package:test_app/child_pages/music_page.dart';
import 'package:test_app/security.dart';

class ChildProvider with ChangeNotifier {
  Map<String, dynamic>? childData;
  String? childId;
  ChildSettings? childPermission;
  String firstName = '';
  String lastName = '';
  String username = '';
  String navigateFrom = '';

  String get childNavigateFrom {
    return navigateFrom;
  }

  set childNavigateFrom(String value) {
    navigateFrom = value;
  }

  Future<void> setChildData(String childId, Map<String, dynamic> data) async {
    this.childId = childId;
    childData = data;

    // Safely handle `iv` decoding
    Uint8List iv = Uint8List(0); // Default to an empty Uint8List
    if (childData!.containsKey('iv') && childData!['iv'] != null) {
      try {
        iv = base64Decode(childData!['iv']);
        print('iv: ${iv.toString()}');
      } catch (decodeError) {
        print('Error decoding IV: $decodeError');
      }
    } else {
      print('IV not provided or null. Proceeding without IV.');
    }

    Uint8List encryptionKey = await getEncryptionKey();

    firstName =
        await decryptChildfield(childData!['first name'], encryptionKey, iv);
    lastName =
        await decryptChildfield(childData!['last name'], encryptionKey, iv);
    username = childData!['username'];

    childPermission = await getChildSettings(childId, encryptionKey, iv);

    // childPermission = await getChildPermissions(childId, data);

    print("Child childPermission: $childPermission");

    notifyListeners();
  }

  Future<void> addSelectedButtonNew({
    required String childId,
    required String text,
    required String iv,
    required Timestamp timestamp,
  }) async {
    try {
      // Get the DateTime from the Timestamp and remove the time part (keep only date)
      DateTime date = timestamp.toDate();
      DateTime truncatedDate =
          DateTime(date.year, date.month, date.day); // Truncate time

      // Create a map of data to be added to Firestore
      Map<String, dynamic> data = {
        'childId': childId,
        'text': text,
        'iv': iv,
        'timestamp': timestamp
      };

      // Add the data to the 'selectedButtons' collection
      await FirebaseFirestore.instance.collection('selectedButtons').add(data);
      print("Data added successfully to selectedButtons.");
    } catch (e) {
      print("Error adding data to selectedButtons: $e");
    }
  }

  Future<void> addSelectedFeelingsNew({
    required String childId,
    required String text,
    required String iv,
    required Timestamp timestamp,
  }) async {
    try {
      // Get the DateTime from the Timestamp and remove the time part (keep only date)
      DateTime date = timestamp.toDate();
      DateTime truncatedDate =
          DateTime(date.year, date.month, date.day); // Truncate time

      // Create a map of data to be added to Firestore
      Map<String, dynamic> data = {
        'childId': childId,
        'text': text,
        'iv': iv,
        'timestamp': timestamp
      };

      // Add the data to the 'selectedFeelings' collection
      await FirebaseFirestore.instance.collection('selectedFeelings').add(data);
      print("Data added successfully to selectedFeelings.");
    } catch (e) {
      print("Error adding data to selectedFeelings: $e");
    }
  }

  Future<void> addSelectedButton(String text, Timestamp timestamp) async {
    if (childId != null) {
      print("childId button: $childId: $text: $timestamp");

      try {
        // Encrypt the text and get the encrypted data
        Map<String, String> encryptedData = await encryptTextWithIV(text);

        addSelectedButtonNew(
            childId: childId!,
            text: encryptedData['text']!,
            iv: encryptedData['iv']!,
            timestamp: timestamp);
        /*
        // Add the encrypted text, IV, and timestamp to Firestore
        await FirebaseFirestore.instance
            .collection('children')
            .doc(childId)
            .update({
          'data.selectedButtons': FieldValue.arrayUnion([
            {
              'text': encryptedData['text'],
              'iv': encryptedData[
                  'iv'], // Store the IV alongside the encrypted text
              'timestamp': timestamp
            }
          ])
        }); */
      } catch (e) {
        throw Exception("Failed to add selected button: $e");
      }
    } else {
      throw Exception("No child logged in");
    }
  }

  Future<void> addSelectedFeelings(String text, Timestamp timestamp) async {
    if (childId != null) {
      try {
        // Use the reusable encryptTextWithIV method
        Map<String, String> encryptedData = await encryptTextWithIV(text);

        addSelectedFeelingsNew(
            childId: childId!,
            text: encryptedData['text']!,
            iv: encryptedData['iv']!,
            timestamp: timestamp);
        /*
        // Update Firestore with the encrypted text and IV
        await FirebaseFirestore.instance
            .collection('children')
            .doc(childId)
            .update({
          'data.selectedFeelings': FieldValue.arrayUnion([
            {
              'text': encryptedData['text'],
              'iv': encryptedData[
                  'iv'], // Store the IV alongside the encrypted text
              'timestamp': timestamp
            }
          ])
        });*/
      } catch (e) {
        throw Exception("Failed to add selected feelings: $e");
      }
    } else {
      throw Exception("No child logged in");
    }
  }

  Future<String?> fetchJson(String jsonName, String childId) async {
    FirebaseStorage storage = FirebaseStorage.instance;
    Reference ref = storage.ref().child('user_folders/$childId/$jsonName');

    final data = await ref.getData();
    if (data != null) {
      String jsonString = String.fromCharCodes(data);
      print('Fetched JSON: $jsonString');
      return jsonString;
    } else {
      print("data not found");
      return null;
    }
  }

  Future<void> changeMusicJson(List<Song> info, String childId) async {
    try {
      List<Map<String, dynamic>> songListJson =
          info.map((song) => song.toJson()).toList();

      String jsonData = json.encode(songListJson);

      final directory = Directory.systemTemp;
      File tempFile = File('${directory.path}/temp.json');
      await tempFile.writeAsString(jsonData);

      Reference ref =
          FirebaseStorage.instance.ref('user_folders/$childId/music.json');
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'application/json',
      );

      UploadTask uploadTask = ref.putFile(tempFile, metadata);
      TaskSnapshot snapshot = await uploadTask;

      print("Songs uploaded to Firebase successfully.");
    } catch (e) {
      print("Error uploading songs: $e");
    }
  }

  Future<void> changeGridJson(Map<String, List> info, String childId) async {
    try {
      String jsonData = json.encode(info);

      final directory = Directory.systemTemp;
      File tempFile = File('${directory.path}/tempGrid.json');
      await tempFile.writeAsString(jsonData);

      Reference ref =
          FirebaseStorage.instance.ref('user_folders/$childId/board.json');
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'application/json',
      );

      UploadTask uploadTask = ref.putFile(tempFile, metadata);
      TaskSnapshot snapshot = await uploadTask;

      print("Board uploaded to Firebase successfully.");
    } catch (e) {
      print("Error uploading songs: $e");
    }
  }

  Future<ChildSettings> getChildPermissions(
      String childId, Map<String, dynamic>? childData) async {
    print("getChildPermissions: $childId");
    Uint8List key = await getEncryptionKey();
    if (childData != null && childData['settings'] != null) {
      String encodedIV = childData['iv'];

      // Decode the IV and encrypted text
      Uint8List iv = base64Decode(encodedIV);

      if (childData['settings'] == null) {
        final localChildPermission = ChildSettings(
          childuid: childId,
          childsecureKey: key,
          audioPage: true,
          emotionHandling: true,
          gridEditing: true,
          sentenceHelper: true,
        );
        childPermission = localChildPermission;
        return childPermission!;
      }

      final encryptedaudioPage = childData?['settings']?['audio page'] ?? true;
      final encryptedemotionHandling =
          childData?['settings']?['emotion handling'] ?? true;
      final encryptedgridEditing =
          childData?['settings']?['grid editing'] ?? true;
      final encryptedsentenceHelper =
          childData?['settings']?['sentence helper'] ?? true;

      bool audioPage =
          (await decryptChildfield(encryptedaudioPage, key, iv)) == 'true';
      bool emotionHandling =
          (await decryptChildfield(encryptedemotionHandling, key, iv)) ==
              'true';
      bool gridEditing =
          (await decryptChildfield(encryptedgridEditing, key, iv)) == 'true';
      bool sentenceHelper =
          (await decryptChildfield(encryptedsentenceHelper, key, iv)) == 'true';

      // Set the child permission settings
      final localChildPermission = ChildSettings(
        childuid: childId,
        childsecureKey: key,
        audioPage: audioPage,
        emotionHandling: emotionHandling,
        gridEditing: gridEditing,
        sentenceHelper: sentenceHelper,
      );
      childPermission = localChildPermission;
    } else {
      final localChildPermission = ChildSettings(
        childuid: childId,
        childsecureKey: key,
        audioPage: false,
        emotionHandling: false,
        gridEditing: false,
        sentenceHelper: false,
      );
      childPermission = localChildPermission;
    }
    return childPermission!;
  }

  Future<String> fetchChildButtonsDataOld() async {
    try {
      DocumentSnapshot childSnapshot = await FirebaseFirestore.instance
          .collection('children')
          .doc(childId)
          .get();

      if (childSnapshot.exists) {
        Map<String, dynamic>? childData =
            childSnapshot.data() as Map<String, dynamic>?;

        if (childData != null &&
            childData['data'] != null &&
            childData['data']['selectedButtons'] != null) {
          Uint8List key = await getEncryptionKey();
          List<dynamic> allButtons = childData['data']['selectedButtons'];

          for (int i = 0; i < allButtons.length; i++) {
            String encryptedText = allButtons[i]['text'];
            String encodedIV = allButtons[i]['iv'];

            // Decode the IV and encrypted text
            Uint8List iv = base64Decode(encodedIV);
            Uint8List encryptedBytes = base64Decode(encryptedText);

            // Decrypt the text
            allButtons[i]['text'] =
                utf8.decode(aesGcmDecrypt(encryptedBytes, key, iv));

            // Convert timestamp to DateTime
            allButtons[i]['timestamp'] = allButtons[i]['timestamp'].toDate();
          }

          print(allButtons);
          var stringList = allButtons.map((e) => e['text']).join(", ");
          print(stringList);
          return stringList;
        } else {
          print("No data");
          return "No data";
        }
      } else {
        print("Document does not exist");
        return "Document does not exist";
      }
    } catch (e) {
      print('Error fetching selected buttons: $e');
      return "Error: $e";
    }
  }

  Future<String> fetchChildFeelingsDataOld() async {
    try {
      DocumentSnapshot childSnapshot = await FirebaseFirestore.instance
          .collection('children')
          .doc(childId)
          .get();

      if (childSnapshot.exists) {
        Map<String, dynamic>? childData =
            childSnapshot.data() as Map<String, dynamic>?;
        if (childData != null &&
            childData['data'] != null &&
            childData['data']['selectedFeelings'] != null) {
          Uint8List key = await getEncryptionKey();

          List<dynamic> allFeelings = childData['data']['selectedFeelings'];
          for (int i = 0; i < allFeelings.length; i++) {
            String encryptedText = allFeelings[i]['text'];
            String encodedIV = allFeelings[i]['iv'];

            // Decode the IV and encrypted text
            Uint8List iv = base64Decode(encodedIV);
            Uint8List encryptedBytes = base64Decode(encryptedText);

            // Decrypt the text
            allFeelings[i]['text'] =
                utf8.decode(aesGcmDecrypt(encryptedBytes, key, iv));

            allFeelings[i]['timestamp'] = allFeelings[i]['timestamp'].toDate();
          }
          var stringList = allFeelings.join(", ");
          return stringList;
        } else {
          print("no data");
          return "no data";
        }
      } else {
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

class ChildCollectionWithKeys {
  // A list to hold child records with their UID and secure keys.
  final List<ChildRecord> _records = [];

  // Private constructor to enforce singleton behavior.
  ChildCollectionWithKeys._privateConstructor();

  // Static instance of the class.
  static final ChildCollectionWithKeys _instance =
      ChildCollectionWithKeys._privateConstructor();

  // Getter to access the singleton instance.
  static ChildCollectionWithKeys get instance => _instance;

  void updateChildTheme(String childuid, String childtheme) {
    final existingIndex =
        _records.indexWhere((record) => record.childuid == childuid);

    if (existingIndex != -1) {
      // Update the existing record.
      _records[existingIndex] = ChildRecord(
        childuid: childuid,
        childsecureKey: _records[existingIndex].childsecureKey,
        childbaserecordiv: _records[existingIndex].childbaserecordiv,
        username: _records[existingIndex].username,
        firstName: _records[existingIndex].firstName,
        lastName: _records[existingIndex].lastName,
        disclaimer: _records[existingIndex].disclaimer,
        childtheme: childtheme,
        settings: _records[existingIndex].settings,
        timestamp: _records[existingIndex].timestamp,
      );
    }
  }

  // Method to add or update a record in the collection.
  void addOrUpdateChildData(
      String childuid,
      Uint8List childsecureKey,
      Uint8List childbaserecordiv,
      String username,
      String firstName,
      String lastName,
      String childtheme,
      String disclaimer,
      Timestamp? timestamp,
      ChildSettings? settings) {
    final existingIndex =
        _records.indexWhere((record) => record.childuid == childuid);

    if (existingIndex != -1) {
      // Update the existing record.
      _records[existingIndex] = ChildRecord(
          childuid: childuid,
          childsecureKey: childsecureKey,
          childbaserecordiv: childbaserecordiv,
          username: username,
          firstName: firstName,
          lastName: lastName,
          disclaimer: disclaimer,
          childtheme: childtheme,
          settings: settings,
          timestamp: timestamp);
    } else {
      // Add a new record.
      _records.add(ChildRecord(
          childuid: childuid,
          childsecureKey: childsecureKey,
          childbaserecordiv: childbaserecordiv,
          username: username,
          firstName: firstName,
          lastName: lastName,
          disclaimer: disclaimer,
          childtheme: childtheme,
          settings: settings,
          timestamp: timestamp));
    }
  }

  // Method to retrieve a record by UID.
  ChildRecord? getRecord(String childuid) {
    return _records.firstWhere(
      (record) => record.childuid == childuid,
      orElse: () => ChildRecord(
          childuid: childuid,
          childsecureKey: Uint8List(0),
          childbaserecordiv: Uint8List(0),
          username: '',
          firstName: '',
          lastName: '',
          childtheme: '',
          disclaimer: '',
          timestamp: null,
          settings:
              ChildSettings(childuid: childuid, childsecureKey: Uint8List(0))),
    );
  }

  Uint8List? getkey(String childuid) {
    return _records
        .firstWhere((record) => record.childuid == childuid,
            orElse: () => ChildRecord(
                  childuid: childuid,
                  childsecureKey: Uint8List(0),
                  childbaserecordiv: Uint8List(0),
                  username: '',
                  firstName: '',
                  lastName: '',
                  disclaimer: '',
                  childtheme: '',
                  timestamp: null,
                ))
        .childsecureKey;
  }

  // Method to remove a record by UID.
  void removeRecord(String childuid) {
    _records.removeWhere((record) => record.childuid == childuid);
  }

  // Method to clear all records (e.g., during a reset or logout).
  void clearAllRecords() {
    _records.clear();
  }

  void dispose() {
    clearAllRecords();
    print('ChildCollectionWithKeys disposed');
  }

  // Getter to access all records.
  List<ChildRecord> get allRecords => List.unmodifiable(_records);

  @override
  String toString() {
    return _records.map((record) => record.toString()).join(', ');
  }
}

class UserListForParentService {
  // Method to generate dropdown items from ChildCollectionWithKeys
  static List<Map<String, String>> generateChildNameDropdownItems() {
    final childCollection = ChildCollectionWithKeys.instance;

    // Traverse the collection and create a list of maps with 'displayText' and 'id'
    final dropdownItems = childCollection.allRecords.map((record) {
      // Combine firstName and lastName with a space
      final fullName =
          "${record.firstName ?? ''} ${record.lastName ?? ''}".trim();

      return {
        'childName': fullName, // Text to show in the dropdown
        'childId': record.childuid, // Corresponding ID
      };
    }).toList();

    return dropdownItems;
  }
}

// Helper class to represent a single child record.
class ChildRecord {
  final String childuid;
  final Uint8List childsecureKey;
  Uint8List? childbaserecordiv;
  String? username;
  String? firstName;
  String? lastName;
  String? childtheme;
  String? disclaimer;
  ChildSettings? settings;
  Timestamp? timestamp;

  ChildRecord(
      {required this.childuid,
      required this.childsecureKey,
      this.childbaserecordiv,
      this.username,
      this.firstName,
      this.lastName,
      this.childtheme,
      this.disclaimer,
      this.settings,
      this.timestamp});

  @override
  String toString() {
    return 'ChildRecord(childuid: $childuid, childsecureKey: ${childsecureKey.length} bytes, childbaserecordiv: ${childbaserecordiv?.length ?? 0} bytes, username: $username, firstName: $firstName, lastName: $lastName, childtheme:$childtheme ,disclaimer:$disclaimer , settings: $settings, timestamp: $timestamp)';
  }
}

class ChildSettings {
  final String childuid;
  final Uint8List childsecureKey;
  Uint8List? childbaserecordiv;
  bool? audioPage;
  bool? emotionHandling;
  bool? gridEditing;
  bool? sentenceHelper;

  ChildSettings(
      {required this.childuid,
      required this.childsecureKey,
      this.childbaserecordiv,
      this.audioPage,
      this.emotionHandling,
      this.gridEditing,
      this.sentenceHelper});

  @override
  String toString() {
    return 'ChildRecord(childuid: $childuid, childsecureKey: ${childsecureKey.length} bytes) , childbaserecordiv: ${childbaserecordiv?.length ?? 0} bytes), audioPage: $audioPage, emotionHandling: $emotionHandling, gridEditing: $gridEditing, sentenceHelper: $sentenceHelper';
  }
}
