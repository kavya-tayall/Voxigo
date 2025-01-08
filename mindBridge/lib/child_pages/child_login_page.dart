import 'package:flutter/material.dart';
import 'package:test_app/parent_pages/privacy_policy.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_app/user_session_management.dart';
import '../main.dart';
import 'package:test_app/parent_pages/parent_login_page.dart';
import '../auth_logic.dart';
import 'package:test_app/authExceptions.dart';
import 'package:test_app/parent_pages/parent_login_widget.dart';

class ChildLoginPage extends StatefulWidget {
  ChildLoginPage({super.key});

  @override
  _ChildLoginPageState createState() => _ChildLoginPageState();
}

class _ChildLoginPageState extends State<ChildLoginPage> {
  final AuthService _auth = AuthService();
  bool isLoading = false;

  String? checkUsername(input) {
    return null;
  }

  Future<String?> _authUser(BuildContext context, LoginData data) async {
    setState(() {
      isLoading = true; // Start loading
    });
    try {
      await logOutUser(context);

      await _auth.signInChild(data.name, data.password, context);
      isSessionValid = true;
    } on ChildDoesNotExistException {
      return ChildDoesNotExistException().toString();
    } catch (e) {
      print(e);
      return e.toString();
    } finally {
      setState(() {
        isLoading = false; // Stop loading
      });
    }
    return null;
  }

  Future<String?> _recoverPassword(String name) async {
    return null;
  }

  void _navigateToParentLogin(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ParentLoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return MouseRegion(
      cursor: isLoading
          ? SystemMouseCursors.progress
          : SystemMouseCursors.basic, // Update cursor based on loading state
      child: AbsorbPointer(
        absorbing: isLoading, // Prevent interactions during loading
        child: Stack(
          children: [
            VoxigoLoginWidget(
              onSignup: (email, password, additionalData) async {
                return 'not implemented';
              },
              onGoogleSignIn: () async => 'not implemented',
              hideSignupButton: true,
              hideForgotPasswordButton: true,
              userType: 'child',
              privacyPolicy: PrivacyPolicyPage(),
              termsOfService: PrivacyPolicyPage(),
              onLogin: (email, password) => _authUser(
                  context, LoginData(name: email, password: password)),
              onRecoverPassword: _recoverPassword,
              userValidator: checkUsername,
              title: "Child Login",
              theme: LoginTheme(
                primaryColor: Color(0xFF56B1FB),
              ),
              footer: "Voxigo",
              onSubmitAnimationCompleted: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => BasePage(),
                ));
              },
            ),
            if (isLoading)
              Center(
                child: CircularProgressIndicator(), // Show loading indicator
              ),
            Positioned(
              top: screenHeight * 0.05, // Adjust dynamically based on height
              right: screenWidth * 0.05, // Adjust dynamically based on width
              child: ElevatedButton(
                onPressed: () {
                  _navigateToParentLogin(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Parent Login",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
