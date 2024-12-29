import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:typed_data'; // For Uint8List type
import 'package:test_app/security.dart';

// ParentRecord class (as provided)
class ParentRecord {
  final String parentUid;
  final Uint8List parentSecureKey;
  Uint8List? parentBaseRecordIv;
  String? username;
  String? name;
  String? firstname;
  String? lastname;
  String? email;

  // Constructor
  ParentRecord({
    required this.parentUid,
    required this.parentSecureKey,
    this.parentBaseRecordIv,
    this.username,
    this.name,
    this.firstname,
    this.lastname,
    this.email,
  });

  // Method to update the fields dynamically
  ParentRecord copyWith({
    String? parentUid,
    Uint8List? parentSecureKey,
    Uint8List? parentBaseRecordIv,
    String? username,
    String? name,
    String? firstname,
    String? lastname,
    String? email,
  }) {
    return ParentRecord(
      parentUid: parentUid ?? this.parentUid,
      parentSecureKey: parentSecureKey ?? this.parentSecureKey,
      parentBaseRecordIv: parentBaseRecordIv ?? this.parentBaseRecordIv,
      username: username ?? this.username,
      name: name ?? this.name,
      firstname: firstname ?? this.firstname,
      lastname: lastname ?? this.lastname,
      email: email ?? this.email,
    );
  }
}

class ParentProvider with ChangeNotifier {
  // Initialize with empty data
  ParentRecord _parentData = ParentRecord(
    parentUid: '',
    parentSecureKey: Uint8List(16), // Empty secure key by default
  );

  // Getter for parent data
  ParentRecord get parentData => _parentData;

  // Method to update the parent data
  void updateParentData({
    String? parentUid,
    Uint8List? parentSecureKey,
    Uint8List? parentBaseRecordIv,
    String? username,
    String? name,
    String? firstname,
    String? lastname,
    String? email,
  }) {
    _parentData = _parentData.copyWith(
      parentUid: parentUid,
      parentSecureKey: parentSecureKey,
      parentBaseRecordIv: parentBaseRecordIv,
      username: username,
      name: name,
      firstname: firstname,
      lastname: lastname,
      email: email,
    );
    notifyListeners(); // Notify listeners to update the UI
  }

  // Fetch parent data using the actual parent UID after authentication
  Future<void> fetchParentData(String parentuid) async {
    try {
      // Fetch parent details and decrypt them using the parent UID
      Map<String, String>? parentDetails =
          await decryptParentDetails(parentuid);
      print('uid inside fetchParentData: $parentuid');
      // If successful, update the provider with real data
      if (parentDetails != null) {
        updateParentData(
          parentUid: parentuid,
          username: parentDetails['username'],
          name: parentDetails['name'],
          firstname: parentDetails['firstname'],
          lastname: parentDetails['lastname'],
          email: parentDetails['email'],
          parentSecureKey: parentDetails['parentSecureKey'] != null
              ? Uint8List.fromList(parentDetails['parentSecureKey']!.codeUnits)
              : null,
          parentBaseRecordIv: parentDetails['parentBaseRecordIv'] != null
              ? Uint8List.fromList(
                  parentDetails['parentBaseRecordIv']!.codeUnits)
              : null,
        );
      } else {
        print("Failed to fetch or decrypt parent details. : $e");
      }
    } catch (e) {
      print("Error in fetching or updating parent data: $e");
    }
  }
}
