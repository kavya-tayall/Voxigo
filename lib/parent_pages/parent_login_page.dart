import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../auth_logic.dart';
import '../child_pages/child_login_page.dart';
import '../main.dart';
import 'package:test_app/authExceptions.dart';

class ParentLoginPage extends StatelessWidget {
  ParentLoginPage({super.key});

  final AuthService _auth = AuthService();

  Future<String?> _authUser(LoginData data, BuildContext context) async {
    try {

      await _auth.signInParent(data.name, data.password, context);
    } on UserNotParentException {
      return 'User is not a parent';
    } on ParentDoesNotExistException {
      return 'Username or password is incorrect';
    } catch (e) {
      return 'Error during login';
    }
    await Future.delayed(const Duration(seconds: 1));
    return null;
  }

  Future<String?> _recoverPassword(String name) async {
    return null;
  }

  Future<String?> _signUp(SignupData data) async {
    try {
      _auth.registerParent(
        data.additionalSignupData!["username"]!,
        "${data.additionalSignupData!["First name"]!} ${data.additionalSignupData!["Last name"]!}",
        data.name!,
        data.password!,
      );
    } on UsernameAlreadyExistsException {
      return "Username already exists";
    } catch (e) {
      return "Registration failed";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterLogin(
          onLogin: (loginData) => _authUser(loginData, context),
          onRecoverPassword: _recoverPassword,
          onSignup: _signUp,
          footer: "MindBridge",
          loginProviders: <LoginProvider>[
            LoginProvider(
              icon: FontAwesomeIcons.google,
              label: 'Google',
              callback: () async {
                return null;
              },
            ),
            LoginProvider(
              icon: FontAwesomeIcons.facebookF,
              label: 'Facebook',
              callback: () async {
                return null;
              },
            ),
            LoginProvider(
              icon: FontAwesomeIcons.apple,
              label: 'Apple',
              callback: () async {
                return null;
              },
            ),
          ],
          additionalSignupFields: [
            UserFormField(
              keyName: "First name",
              userType: LoginUserType.firstName,
            ),
            UserFormField(
              keyName: "Last name",
              userType: LoginUserType.lastName,
            ),
            UserFormField(
              keyName: "username",
              userType: LoginUserType.name,
            ),
          ],
          title: "Parent Login",
          userType: LoginUserType.email,
          theme: LoginTheme(
            primaryColor: Color(0xFF56B1FB),
          ),
          onSubmitAnimationCompleted: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => ParentBasePage(),
              ),
            );
          },
        ),

        Positioned(
          top: 50,
          right: 20,
          child: ElevatedButton(
            onPressed: () {
              _navigateToChildLogin(context);
            },
            child: Text("Child Login"),
          ),
        ),
      ],
    );
  }

  // Navigate to child login page
  void _navigateToChildLogin(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChildLoginPage()),
    );
  }
}

