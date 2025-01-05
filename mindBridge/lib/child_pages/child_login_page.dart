import 'package:flutter/material.dart';
import 'package:test_app/parent_pages/privacy_policy.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_app/user_session_management.dart';
import '../main.dart';
import 'package:test_app/parent_pages/parent_login_page.dart';
import '../auth_logic.dart';
import 'package:test_app/authExceptions.dart';
import 'package:test_app/parent_pages/parent_login_widget.dart';

class ChildLoginPage extends StatelessWidget {
  ChildLoginPage({super.key});
  final AuthService _auth = AuthService();

  String? checkUsername(input) {
    return null;
  }

  Future<String?> _authUser(BuildContext context, LoginData data) async {
    try {
      await logOutUser(context);

      await _auth.signInChild(data.name, data.password, context);
      isSessionValid = true;
    } on ChildDoesNotExistException {
      return ChildDoesNotExistException().toString();
    } catch (e) {
      print(e);
      return e.toString();
    }
    return null;
  }

  Future<String?> _recoverPassword(String name) async {
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Clear any previous user session before starting the login process
    // logOutUser(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        VoxigoLoginWidget(
          onSignup: (email, password, additionalData) async {
            // Implement your signup logic here
            return 'not implemented';
          },
          onGoogleSignIn: () async => 'not implemented',
          hideSignupButton: true,
          hideForgotPasswordButton: true,
          userType: 'child',
          privacyPolicy: PrivacyPolicyPage(),
          termsOfService: PrivacyPolicyPage(),
          onLogin: (email, password) =>
              _authUser(context, LoginData(name: email, password: password)),
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
        Positioned(
          top: screenHeight * 0.05, // Adjust dynamically based on screen height
          right: screenWidth * 0.05, // Adjust dynamically based on screen width
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
                  color: Colors.blueAccent), // Smaller text for better fit
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToParentLogin(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ParentLoginPage()),
    );
  }
}
