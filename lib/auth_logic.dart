import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'authExceptions.dart';

import 'widgets/child_provider.dart';
import 'cache_utility.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<User?> registerParent(String username, String name, String email, String password) async {
    bool usernameExists = await _checkUsernameExists(username);

    print(usernameExists);
    if (usernameExists) {
      throw UsernameAlreadyExistsException();
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? parent = userCredential.user;

      if (parent != null) {
        await _db.collection('parents').doc(parent.uid).set({
          'email': email,
          'username': username,
          'name': name,
          'role': 'parent',
          'children': []
        });
      }
      return parent;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<bool> _checkUsernameExists(String username) async {
    QuerySnapshot parentResult = await _db.collection('parents')
        .where('username', isEqualTo: username)
        .get();

    print(parentResult.docs.isNotEmpty);
    return parentResult.docs.isNotEmpty;
  }

  Future<User?> signInParent(String email, String password, BuildContext context) async {
    print("called func");
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      print("done");
      User? parent = userCredential.user;
      print(parent);

      if (parent != null) {
        DocumentSnapshot userDoc = await _db.collection('parents').doc(parent.uid).get();
        if (userDoc.exists && userDoc['role'] == 'parent') {
          await _fetchAndStoreChildrenData(userDoc['children'], context);
          return parent;
        } else {
          throw UserNotParentException();
        }
      } else {
        throw ParentDoesNotExistException();
      }
    } catch (e) {
      print(e.toString());
      throw OtherError();
    }
  }

  Future<void> _fetchAndStoreChildrenData(List<dynamic> childrenIds, BuildContext context) async {
    final childProvider = Provider.of<ChildProvider>(context, listen: false);

    for (String childId in childrenIds) {
      DocumentSnapshot childDoc = await _db.collection('children').doc(childId).get();

      if (childDoc.exists) {
        var childData = childDoc.data() as Map<String, dynamic>;
        childProvider.setChildData(childId, childData);

        try {

          String? boardJsonString = await childProvider.fetchJson("board.json");
          final Map<String, dynamic> boardData = json.decode(boardJsonString!);
          await downloadFromList(boardData["buttons"]!);


          String? musicJsonString = await childProvider.fetchJson("music.json");
          final List<dynamic> musicData = json.decode(musicJsonString!);

          for (int i = 0; i < musicData.length; i++) {
            await downloadMp3(musicData[i]['link']);
            await downloadCoverImage(musicData[i]['image']);
          }
        } catch (e) {
          print(e);
        }
      }
    }
  }

  Future<Map<String, dynamic>?> signInChild(String username, String password, BuildContext context) async {
    QuerySnapshot childQuery = await _db.collection('children')
        .where('username', isEqualTo: username)
        .where('password', isEqualTo: password)
        .get();

    if (childQuery.docs.isNotEmpty) {
      var childData = childQuery.docs.first.data() as Map<String, dynamic>;
      var childId = childQuery.docs.first.id;

      final childProvider = Provider.of<ChildProvider>(context, listen: false);
      childProvider.setChildData(childId, childData);

      try {
        String? boardJsonString = await childProvider.fetchJson("board.json");
        final Map<String, dynamic> data2 = json.decode(boardJsonString!);
        await downloadFromList(data2["buttons"]!);

        String? musicJsonString = await childProvider.fetchJson("music.json");
        final List<dynamic> data = json.decode(musicJsonString!);

        for (int i = 0; i < data.length; i++) {
          await downloadMp3(data[i]['link']);
          await downloadCoverImage(data[i]['image']);
        }
      } catch (e) {
        print(e);
      }
      return childData;
    } else {
      throw ChildDoesNotExistException();
    }
  }
}


class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final storage = FirebaseStorage.instance;

  Future<DocumentReference?> registerChild(String parentId, String firstName, String lastName, String username, String password) async {
    bool usernameExists = await _checkUsernameExists(username);

    if (usernameExists) {
      throw UsernameAlreadyExistsException();
    }

    DocumentReference childRef = await _db.collection('children').add({
      'username': username,
      'first name': firstName,
      'last name': lastName,
      'password': password, // Consider hashing this password for security
      'parents': [parentId],
      'data': {'selectedButtons': [], 'selectedFeelings': []},
    });


    await _db.collection('parents').doc(parentId).update({
      'children': FieldValue.arrayUnion([childRef.id])
    });

    await uploadJsonFromAssets('assets/board_info/board.json', '/user_folders/$username/board.json');
    await uploadJsonFromAssets('assets/songs/music.json', '/user_folders/$username/music.json');


    try{
      String jsonString = await rootBundle.loadString('assets/songs/music.json');
      final List<dynamic> data = json.decode(jsonString);

      for (int i=0;i<data.length; i++){
        await downloadMp3(data[i]['link']);
        await downloadCoverImage(data[i]['image']);
      }
    } catch(e){
      print(e);
    }


    try{
      String jsonString = await rootBundle.loadString('assets/board_info/board.json');
      final Map<String, dynamic> data2 = json.decode(jsonString);

      await downloadFromList(data2["buttons"]!);
    } catch(e){
      print(e);
    }


  }

  Future<bool> _checkUsernameExists(String username) async {
    QuerySnapshot childResult = await _db.collection('children')
        .where('username', isEqualTo: username)
        .get();

    return childResult.docs.isNotEmpty;
  }

  Future<void> uploadJsonFromAssets(String assetPath, String destinationPath) async {
    try {
      String jsonString = await rootBundle.loadString(assetPath);

      final directory = Directory.systemTemp;
      File tempFile = File('${directory.path}/temp.json');
      await tempFile.writeAsString(jsonString);

      FirebaseStorage storage = FirebaseStorage.instance;
      Reference storageRef = storage.ref(destinationPath);

      final SettableMetadata metadata = SettableMetadata(contentType: 'application/json',);

      UploadTask uploadTask = storageRef.putFile(tempFile, metadata);
      TaskSnapshot snapshot = await uploadTask;

      FullMetadata fileMetadata = await storageRef.getMetadata();
      print('Uploaded file content type: ${fileMetadata.contentType}');

    } catch (e) {
      print('Error uploading JSON file: $e');
    }
  }



}


