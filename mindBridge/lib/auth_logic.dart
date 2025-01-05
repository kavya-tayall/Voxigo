import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:test_app/getauthtokenandkey.dart';
import 'package:test_app/widgets/theme_provider.dart'; // Ensure this import is correct
import 'package:test_app/security.dart';
import 'authExceptions.dart';

import 'widgets/child_provider.dart';
import 'widgets/parent_provider.dart';
import 'cache_utility.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_app/user_session_management.dart';

class InvalidCredentialsException implements Exception {
  final String message;

  InvalidCredentialsException([this.message = "Invalid credentials"]);

  @override
  String toString() => message;
}

Future<bool> validateParentPassword(String email, String password) async {
  try {
    // Get the current user
    User? user = FirebaseAuth.instance.currentUser;
    String? email = user?.email;

    if (user == null) {
      throw Exception('No user is currently logged in.');
    }

    // Create a credential object with the user's email and password
    AuthCredential credential = EmailAuthProvider.credential(
      email: email!,
      password: password,
    );

    // Reauthenticate the user with the credentials
    await user.reauthenticateWithCredential(credential);

    // If reauthentication is successful, return true
    return true;
  } catch (e) {
    // If reauthentication fails, handle the error and return false
    print('Reauthentication failed: $e');
    return false;
  }
}

Future<void> logOutUser(BuildContext context) async {
  try {
    ApiService.instance.dispose();
    UserSession.instance.dispose();
    ChildCollectionWithKeys.instance.dispose();
    print('All singleton classes disposed during logout');
    final childProvider = Provider.of<ChildProvider>(context, listen: false);
    childProvider.logout();
    final parentProvider = Provider.of<ParentProvider>(context, listen: false);
    parentProvider.clearParentData();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await FirebaseAuth.instance.signOut();
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.setdefaultTheme();
  } catch (e) {
    print("Error logging out: $e");
  }
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<User?> registerParent(
    String username,
    String firstname,
    String lastname,
    String email, [
    String? password,
    bool createUserOrNot = true,
  ]) async {
    // Check if the username already exists
    /*
    bool usernameExists = await _checkUsernameExists(username);

    if (usernameExists) {
      throw UsernameAlreadyExistsException();
    }*/

    // Enforce password requirement if creating a new user
    if (createUserOrNot && (password == null || password.isEmpty)) {
      throw PasswordRequiredException(
          'Password is required to create a new user.');
    }

    User? parent;

    try {
      if (createUserOrNot) {
        // Create user with email and password
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password!,
        );
        parent = userCredential.user;

        if (parent == null) {
          throw Exception("User not created");
        }

        // Send email verification
        await parent.sendEmailVerification();
        print("Verification email sent to ${parent.email}");
      } else {
        parent = _auth.currentUser;
      }

      print("Now creating parent in table with uid ${parent!.uid}");
      print("username $username");
      print("email $email");
      print("firstname $firstname");
      print("lastname $lastname");

      await ApiService.initialize();

      await setLoginUserKeys(parent, UserType.parent);

      final encryptedParentInfo = await encryptParentInfoWithIV(
          parent.uid, username, email, firstname, lastname);
      print("encryptedParentInfo $encryptedParentInfo");

      if (parent != null) {
        // Save user details in Firestore
        await _db.collection('parents').doc(parent.uid).set({
          'email': encryptedParentInfo['email'],
          'username': encryptedParentInfo['username'],
          'firstname': '${encryptedParentInfo['firstname']}',
          'lastname': '${encryptedParentInfo['lastname']}',
          'role': 'parent',
          'children': [],
          'iv': encryptedParentInfo['iv'],
        });
      }
      return parent;
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  Future<bool> checkAdditionalInfo(
      String email, String userId, ParentRecord parentData) async {
    String? savedEmail = parentData.email;

    // If saved email is null or empty, return false
    if (savedEmail == null || savedEmail.isEmpty) {
      return false;
    }

    // If the provided email doesn't match the saved email in parentData
    if (savedEmail != email) {
      return false;
    }

    // Check if name or username fields are missing or empty
    String? name = parentData.firstname;

    if (name == null || name.trim().isEmpty) {
      return false;
    }

    // If email, username, and name all exist, return true (indicating additional info is not required)
    return true;
  }

  Future<bool> _checkUsernameExists(String username) async {
    QuerySnapshot parentResult = await _db
        .collection('parents')
        .where('username', isEqualTo: username)
        .get();

    print(parentResult.docs.isNotEmpty);
    return parentResult.docs.isNotEmpty;
  }

  Future<User?> signInParentwithEmailandPassword(
      String email, String password, BuildContext context) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      User? parent = userCredential.user;

      if (parent != null) {
        if (!parent.emailVerified) {
          throw EmailNotVerifiedException();
        }
        return await postParentLogin(parent!);
      } else {
        throw ParentDoesNotExistException();
      }
    } catch (e) {
      print('hello');
      if (e.toString().contains('firebase_auth/invalid-credential')) {
        throw InvalidCredentialsException();
      } else if (e is FirebaseAuthException) {
        // Specific FirebaseAuthException handling
        switch (e.code) {
          case 'user-not-found':
          case 'wrong-password':
            throw InvalidCredentialsException();
          case 'user-disabled':
            throw Exception('User account has been disabled.');
          default:
            throw Exception('An unexpected error occurred.');
        }
      } else {
        // Non-FirebaseAuthException handling
        print(e.toString());
        rethrow;
      }
    } finally {
      print("Parent Login done");
    }
  }

  Future<User?> postParentLogin(User parent) async {
    //   DocumentSnapshot userDoc =
    //     await _db.collection('parents').doc(parent.uid).get();
    //   if (userDoc.exists && userDoc['role'] == 'parent') {
    //  await _fetchAndStoreChildrenData(userDoc['children'], context, email);

    ChildCollectionWithKeys.instance.dispose();

    await ApiService.initialize();

    await setLoginUserKeys(parent, UserType.parent);

    await saveLoginType('parent'); // Save the login type
    await setUserSessionActive(parent.uid!);
    listenToUserSession(parent.uid);

    return parent;
    //  } else {
    //  throw UserNotParentException();
    // }
  }

  Future<void> setLoginUserKeys(User user, UserType userType) async {
    String? token = await user.getIdToken();

    final apiService = ApiService.instance;

    final requestBodyForKey = {
      'token': token,
    };

    final encryptionKey =
        await apiService.getEncryptionKeyfromVault(requestBodyForKey);

    print("Encryption Key: ${base64Encode(encryptionKey)}");
    print("User Type: $userType");
    print("User UID: ${user.uid}");

    UserSession.instance.initialize(
      uid: user.uid,
      secureKey: encryptionKey,
      userType: userType,
    );
  }

/*
  Future<void> _fetchAndStoreChildrenData(List<dynamic> childrenIds,
      BuildContext context, String parentusername) async {
    final childProvider = Provider.of<ChildProvider>(context, listen: false);

    for (String childId in childrenIds) {
      DocumentSnapshot childDoc =
          await _db.collection('children').doc(childId).get();

      if (childDoc.exists) {
        var childData = childDoc.data() as Map<String, dynamic>;
        childProvider.setChildData(childId, childData);
        //String childUsername = childData['username'];

        try {
          String? boardJsonString = await childProvider.fetchJson("board.json");
          final Map<String, dynamic> boardData = json.decode(boardJsonString!);

          print('calling fetchButtonLogsAndDownloadImages for $parentusername');
          await fetchButtonLogsAndDownloadImages(
              parentusername, boardData["buttons"]!);

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
  }*/

  Future<void> saveChildToken(String token, String userName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('childToken', token);
    await saveLoginType('child'); // Save the login type
    await saveLoginUser(userName);
  }

  Future<void> saveLoginType(String loginType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'loginType', loginType); // Save either "parent" or "child"
  }

  Future<void> saveLoginUser(String userName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'loginUser', userName); // Save either "parent" or "child"
  }

  Future<void> signInChild(
      String username, String password, BuildContext context,
      {bool alreadyAuth = false}) async {
    // Query Firestore for the username
    QuerySnapshot childQuery = await _db
        .collection('children')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    if (childQuery.docs.isEmpty) {
      throw ChildDoesNotExistException();
    }

    var childData = childQuery.docs.first.data() as Map<String, dynamic>;

    if (!alreadyAuth) {
      var storedHashedPassword = childData['password'] as String;
      // Validate the entered password against the hashed password
      if (!BCrypt.checkpw(password, storedHashedPassword)) {
        throw InvalidCredentialsException(); // Custom exception for invalid credentials
      }
    }

    var childId = childQuery.docs.first.id;

    await ApiService.initialize();

    final apiService = ApiService.instance;

    final firebaseToken = await apiService.getFirebaseToken(childId);

    UserCredential userCredential = await signInWithCustomToken(firebaseToken);

    User? child = userCredential.user;

    if (child != null) {
      await setLoginUserKeys(child, UserType.child);
    } else {
      print("No user found");
    }

    saveChildToken(firebaseToken, username);
    await setUserSessionActive(childId);
    listenToUserSession(childId);

    // Set child data in the provider
    final childProvider = Provider.of<ChildProvider>(context, listen: false);
    childProvider.setChildData(childId, childData);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    await themeProvider.loadTheme(
        isChild: true); // Load the theme from Firebase
  }
}

Future<UserCredential> signInWithCustomToken(String customToken) async {
  try {
    final FirebaseAuth auth = FirebaseAuth.instance;

    // Authenticate using the custom token
    UserCredential userCredential =
        await auth.signInWithCustomToken(customToken);

    // Access the authenticated user
    User? user = userCredential.user;
    if (user != null) {
      print("User signed in: ${user.uid}");
      return userCredential;
    } else {
      print("No user found.");
      throw Exception("No user found.");
    }
  } catch (e) {
    print("Error signing in with custom token: $e");
    throw Exception("Error signing in with custom token: $e");
  }
}

String generateFirebaseId() {
  final docRef = FirebaseFirestore.instance.collection('children').doc();
  String generatedId = docRef.id;
  print('Generated ID: $generatedId');
  return generatedId;
}

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> encryptChildDataAndRegister(
      String parentId,
      String firstName,
      String lastName,
      String username,
      String password,
      String disclaimer) async {
    try {
      // Check if the username already exists
      bool usernameExists = await _checkUsernameExists(username);

      if (usernameExists) {
        throw UsernameAlreadyExistsException();
      }

      // Encrypt the password using bcrypt
      final String hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

      // Generate a unique ID for the child
      final String childId = generateFirebaseId();
      print('Now doing encyrption for registering child with id $childId');

      // Encrypt the child data
      final Map<String, dynamic> encryptedData = await encryptChildInfoWithIV(
          parentId,
          childId,
          username,
          firstName,
          lastName,
          'default',
          disclaimer,
          'add');
      print('after encyrption registering child with id $childId');
      // Register the child with the encrypted data
      await registerChild(
        childId,
        parentId,
        encryptedData['first name'],
        encryptedData['last name'],
        encryptedData['disclaimer'],
        encryptedData['username'],
        hashedPassword,
        encryptedData['timestamp'],
        jsonDecode(encryptedData['settings']),
        iv: encryptedData['iv'],
      );

      return childId;
    } catch (e) {
      // Handle and log errors appropriately
      print('Error in encryptChildDataAndRegister: $e');

      if (e is UsernameAlreadyExistsException) {
        rethrow; // Rethrow specific exceptions to be handled by the caller
      } else {
        throw Exception(
            'An unexpected error occurred during child registration.');
      }
    }
  }

  /// Deletes a child by username, ensuring the username exists and handles errors gracefully.
  Future<void> deleteChildByUsername(String username) async {
    try {
      // Fetch child ID based on username
      QuerySnapshot childQuery = await _db
          .collection('children')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (childQuery.docs.isEmpty) {
        throw ChildDoesNotExistException(); // Custom exception for non-existent child
      }

      var childId = childQuery.docs.first.id;

      // Perform deletion of the child
      await deleteChild(childId, username);

      print('Child with username "$username" deleted successfully.');
    } catch (e) {
      print('Error in deleteChildByUsername: $e');
      if (e is ChildDoesNotExistException) {
        throw Exception('The specified username does not exist.');
      }
      throw Exception('Failed to delete child by username. Please try again.');
    }
  }

  /// Deletes a child document and its associated data from Firestore, Firebase Storage, and local storage.
  Future<void> deleteChild(String childId, String username) async {
    try {
      // Fetch the parent ID from the current user
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user is currently logged in.');
      }
      String parentId = user.uid;

      // Verify that the child belongs to the logged-in parent
      DocumentSnapshot parentDoc =
          await _db.collection('parents').doc(parentId).get();

      if (!parentDoc.exists) {
        throw Exception('Parent data not found.');
      }

      var parentData = parentDoc.data() as Map<String, dynamic>;
      List<dynamic> children = parentData['children'] ?? [];

      if (!children.contains(childId)) {
        throw Exception(
            'The specified child does not exist or is not associated with the logged-in user.');
      }

      // Remove childId from the parent's children array
      await _db.collection('parents').doc(parentId).update({
        'children': FieldValue.arrayRemove([childId]),
      });

      print('Child ID removed from parent\'s children array.');

      await removeChildFromParentField(parentId, childId);

      // Reference to the child document in Firestore
      DocumentReference childRef = _db.collection('children').doc(childId);

      // Delete the child document in Firestore
      await childRef.delete();
      print('Child document deleted.');

      DocumentReference childlogRef =
          _db.collection('button_log').doc(username);
      await childlogRef.delete();

      DocumentReference childmp3logRef =
          _db.collection('mp3_log').doc(username);
      await childmp3logRef.delete();

      DocumentReference childappinslogRef =
          _db.collection('app_installations').doc(username);
      await childappinslogRef.delete();

      // Delete the child's folder in Firebase Storage
      await deleteFolder('user_folders/$childId');
      print('Child\'s folder deleted from Firebase Storage.');

      // Delete the child's local folder
      await deleteLocalChildFolder(childId);
      print('Child\'s local folder deleted.');

      ChildCollectionWithKeys.instance.removeRecord(childId);
    } catch (e) {
      print('Error deleting child $childId: $e');
      throw Exception('Failed to delete child. Please try again.');
    }
  }

  Future<void> deleteParentAccount() async {
    try {
      // Fetch the parent ID from the current user
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('No user is currently logged in.');
      }
      String parentId = user.uid;

      // Delete all child accounts associated with the parent
      final childAccounts = await _db
          .collection('children')
          .where('parentId', isEqualTo: parentId)
          .get();

      for (var doc in childAccounts.docs) {
        print('Deleting child account: ${doc['username']}');
        await deleteChildByUsername(doc['username']);
      }

      // Delete the parent document in Firestore
      await _db.collection('parents').doc(parentId).delete();
      print('Parent document deleted.');

      // Delete the parent account from firebase auth
      await user.delete();
    } catch (e) {
      print('Error deleting parent account: $e');
      throw Exception('Failed to delete child. Please try again.');
    }
  }

// Register Child (No Email Verification Added)
  Future<DocumentReference?> registerChild(
      String customDocIdForChild,
      String parentId,
      String firstName,
      String lastName,
      String disclaimer,
      String username,
      String password,
      String timestamp,
      Map<String, dynamic> settings,
      {String iv = ''}) async {
    // Create a document reference with the custom ID
    DocumentReference childRef =
        _db.collection('children').doc(customDocIdForChild);

    // Set the data for the document
    await childRef.set({
      'username': username,
      'first name': firstName,
      'last name': lastName,
      'password': password,
      'parents': [parentId],
      'disclaimer': disclaimer,
      if (iv.isNotEmpty) 'iv': iv,
      'data': {'selectedButtons': [], 'selectedFeelings': []},
      'settings': {
        'sentence helper': settings['sentence helper'],
        'emotion handling': settings['emotion handling'],
        'grid editing': settings['grid editing'],
        'audio page': settings['audio page'],
        'theme': settings['childtheme'],
      }
    });

    await _db.collection('parents').doc(parentId).update({
      'children': FieldValue.arrayUnion(
          [childRef.id]), // Keep the existing 'children' field intact
    });
    await updateParentChildrenField(parentId, customDocIdForChild);

    await uploadJsonFromAssets('assets/board_info/board.json',
        '/user_folders/$customDocIdForChild/board.json');
    await uploadJsonFromAssets('assets/songs/music.json',
        '/user_folders/$customDocIdForChild/music.json');
    // Set child data in the provider

    await copyAllAssetsToAppFolder(customDocIdForChild);
    await copyMusicToLocalHolderFromAsset(customDocIdForChild);
/*
    try {
      String jsonString =
          await rootBundle.loadString('assets/songs/music.json');
      final List<dynamic> data = json.decode(jsonString);

      for (int i = 0; i < data.length; i++) {
        await downloadMp3(data[i]['link'], customDocIdForChild);
        await downloadCoverImage(data[i]['image'], customDocIdForChild);
      }
    } catch (e) {
      print(e);
    }*/
/*
    try {
      String jsonString =
          await rootBundle.loadString('assets/board_info/board.json');
      final Map<String, dynamic> data2 = json.decode(jsonString);

      await downloadAllImagesFromJsonList(data2["buttons"]!,
          username: username, childId: customDocIdForChild);
    } catch (e) {
      print(e);
    }*/
  }

  Future<bool> _checkUsernameExists(String username) async {
    QuerySnapshot childResult = await _db
        .collection('children')
        .where('username', isEqualTo: username)
        .get();

    return childResult.docs.isNotEmpty;
  }

  Future<void> uploadJsonFromAssets(
      String assetPath, String destinationPath) async {
    try {
      String jsonString = await rootBundle.loadString(assetPath);

      final directory = Directory.systemTemp;
      File tempFile = File('${directory.path}/temp.json');
      await tempFile.writeAsString(jsonString);

      FirebaseStorage storage = FirebaseStorage.instance;
      Reference storageRef = storage.ref(destinationPath);

      final SettableMetadata metadata = SettableMetadata(
        contentType: 'application/json',
      );

      UploadTask uploadTask = storageRef.putFile(tempFile, metadata);
      TaskSnapshot snapshot = await uploadTask;

      FullMetadata fileMetadata = await storageRef.getMetadata();
      print('Uploaded file content type: ${fileMetadata.contentType}');
    } catch (e) {
      print('Error uploading JSON file: $e');
    }
  }
}

Future<String?> getCurrentLoginUserToken() async {
  try {
    // Get the currently authenticated user
    User? user = FirebaseAuth.instance.currentUser;

    // Check if the user is signed in
    if (user != null) {
      // Get the ID token
      String? token = await user.getIdToken();

      // Optionally, you can force token refresh by passing true
      // String token = await user.getIdToken(true);

      return token;
    } else {
      print("No user is logged in.");
      return null;
    }
  } catch (e) {
    print("Error getting user token: $e");
    return null;
  }
}
