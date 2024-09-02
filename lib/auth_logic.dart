import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';




class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future <User?> registerParent(String username, String name, String email, String password) async {
    bool usernameExists = await _checkUsernameExists(username);

    print(usernameExists);
    if (usernameExists) {
      throw UsernameAlreadyExistsException();
    }

    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
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

  Future<User?> signInParent(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? parent = userCredential.user;


      if (parent != null) {
        DocumentSnapshot userDoc = await _db.collection('parents').doc(parent.uid).get();
        if (userDoc.exists && userDoc['role'] == 'parent') {
          return parent;
        } else {
          throw UserNotParentException();
        }
      } else {
        throw ParentDoesNotExistException();
      }
    } catch (e) {
      print(e.toString());
      throw ParentDoesNotExistException();
    }
  }

  Future<Map<String, dynamic>?> signInChild(String username, String password) async {
    QuerySnapshot childQuery = await _db.collection('children')
        .where('username', isEqualTo: username)
        .where('password', isEqualTo: password)
        .get();

    if (childQuery.docs.isNotEmpty) {
      return childQuery.docs.first.data() as Map<String, dynamic>?;
    } else {
      throw ChildDoesNotExistException();
    }
  }
}


class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
      'data': {}
    });

    await _db.collection('parents').doc(parentId).update({
      'children': FieldValue.arrayUnion([childRef.id])
    });
    return childRef;
  }

  Future<bool> _checkUsernameExists(String username) async {
    QuerySnapshot childResult = await _db.collection('children')
        .where('username', isEqualTo: username)
        .get();

    return childResult.docs.isNotEmpty;
  }
}


class UsernameAlreadyExistsException implements Exception {
  final String message;

  UsernameAlreadyExistsException([this.message = 'Username already exists']);

  @override
  String toString() {
    return "CustomException: $message";
  }
}

class UserNotParentException implements Exception {
  final String message;

  UserNotParentException([this.message = 'User is not a parent']);

  @override
  String toString() {
    return "CustomException: $message";
  }
}

class ParentDoesNotExistException implements Exception {
  final String message;

  ParentDoesNotExistException(
      [this.message = 'Email or password is incorrect']);

  @override
  String toString() {
    return "CustomException: $message";
  }
}

class ChildDoesNotExistException implements Exception {
  final String message;

  ChildDoesNotExistException(
      [this.message = 'Username or password is incorrect']);

  @override
  String toString() {
    return "CustomException: $message";
  }
}