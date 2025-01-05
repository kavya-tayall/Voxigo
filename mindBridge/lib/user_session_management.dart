import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

bool isSessionValid = true; // Global variable to track session validity

// Set user session as active
Future<void> setUserSessionActive(String userId) async {
  await _firestore.collection('user_sessions').doc(userId).set({
    'active': true,
    'lastLogin':
        FieldValue.serverTimestamp(), // Server timestamp for last login
  });
}

// Set user session as inactive (for revocation)
Future<void> setUserSessionInactive(String userId) async {
  await _firestore.collection('user_sessions').doc(userId).update({
    'active': false, // Mark session as inactive
  });
}

// Delete the user session (for full session revocation)
Future<void> deleteUserSession(String userId) async {
  await _firestore.collection('user_sessions').doc(userId).delete();
}

// Listen for changes in the user session and update the global variable
void listenToUserSession(String userId) {
  final userSessionRef = _firestore.collection('user_sessions').doc(userId);

  // Listen for document changes
  userSessionRef.snapshots().listen((snapshot) {
    if (snapshot.exists) {
      final data = snapshot.data();
      final isActive = data?['active'] ?? false;

      if (!isActive) {
        // Mark session invalid globally
        isSessionValid = false;
        FirebaseAuth.instance.signOut();
        print('User session has been revoked. Logging out...');
      }
    } else {
      // Mark session invalid globally
      isSessionValid = false;
      FirebaseAuth.instance.signOut();
      print('User session has been deleted. Logging out...');
    }
  });
}

class SessionExpiredWidget extends StatelessWidget {
  final VoidCallback onLogout;

  const SessionExpiredWidget({Key? key, required this.onLogout})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "There was an issue with your session. To continue, please log in again.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                onLogout();
                Navigator.of(context).pushReplacementNamed('/parent_login');
              },
              child: const Text("Log out"),
            ),
          ],
        ),
      ),
    );
  }
}
