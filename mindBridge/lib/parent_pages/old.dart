import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart'; // For Google sign-in
import 'package:test_app/security.dart';

import '../auth_logic.dart';
import '../child_pages/child_login_page.dart';
import '../main.dart';
import 'package:test_app/authExceptions.dart';
import 'package:test_app/widgets/parent_provider.dart'; // Adjust the path as necessary
import 'package:provider/provider.dart'; // Add this line

class ParentLoginPage extends StatelessWidget {
  ParentLoginPage({super.key});

  final AuthService _auth = AuthService();

  Future<String?> _authUser(LoginData data, BuildContext context) async {
    try {
      print("ParentLoginPage: _authUser: ${data.name}, ${data.password}");
      await _auth.signInParentwithEmailandPassword(
          data.name, data.password, context);
    } on UserNotParentException {
      return 'User is not a parent';
    } on ParentDoesNotExistException {
      return 'Username or password is incorrect';
    } catch (e) {
      if (e.toString().contains('The email address is badly formatted')) {
        return 'Username or password is incorrect';
      } else if (e.toString().contains('auth credential is incorrect')) {
        return 'Username or password is incorrect';
      }
      print("Unexpected error: $e");
      return e.toString();
    }
    await Future.delayed(const Duration(seconds: 1));
    return null;
  }

  Future<String?> _recoverPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found for that email.';
        case 'invalid-email':
          return 'The email address is not valid.';
        default:
          return 'An error occurred. Please try again later.';
      }
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  Future<String?> _signUp(SignupData data) async {
    try {
      print("ParentLoginPage: _signUp:");
      await _auth.registerParent(
        data.additionalSignupData!["username"]!,
        data.additionalSignupData!["First name"]!,
        data.additionalSignupData!["Last name"]!,
        data.name!, //for email address
        data.password!,
        true,
      );
    } on UsernameAlreadyExistsException {
      print("Username already exists");
      return "Username already exists";
    } catch (e) {
      if (e
          .toString()
          .contains('The email address is already in use by another account')) {
        print("Email already exists");
        return "The email address is already in use by another account";
      }
      print("Unexpected error: $e");
      return "Registration failed";
    }

    return null; // Registration successful
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        FlutterLogin(
          onLogin: (loginData) => _authUser(loginData, context),
          onRecoverPassword: _recoverPassword,
          onSignup: _signUp,
          footer: "Voxigo",
          messages: LoginMessages(
            recoverPasswordIntro:
                'Please enter the email address associated with your account.',
            recoverPasswordDescription:
                'We will send you a link to reset your password.',
          ),
          savedEmail: '',
          savedPassword: '',
          loginProviders: <LoginProvider>[
            LoginProvider(
              icon: FontAwesomeIcons.google,
              label: 'Google',
              callback: () async {
                print('Starting Google Sign-In...');
                final result = await _googleSignIn(context);
                return result;
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
          userValidator: (value) {
            if (value == null || value.isEmpty) {
              return 'Username is required';
            }
            return null;
          },
          passwordValidator: (value) {
            if (value == null || value.isEmpty) {
              return 'Password is required';
            }
            return null;
          },
          loginAfterSignUp: false,
          onSubmitAnimationCompleted: () async {
            User? user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              print("ParentLoginPage: _authUser: ${user.email}");

              await _auth.postParentLogin(user);

              ParentProvider parentProvider =
                  Provider.of<ParentProvider>(context, listen: false);

              await parentProvider.fetchParentData(user.uid);

              bool checkAdditionalInfo = await _auth.checkAdditionalInfo(
                  user.email!, user.uid, parentProvider.parentData);

              bool needsAdditionalInfo;

              if (checkAdditionalInfo == true) {
                needsAdditionalInfo = false;
              } else {
                needsAdditionalInfo = true;
              }

              if (needsAdditionalInfo) {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) =>
                      AdditionalInfoScreen(user: user, auth: _auth),
                ));
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => ParentBasePage()),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Authentication failed. Please try again.')),
              );
            }
          },
        ),
        Positioned(
          top: screenHeight * 0.05, // Adjust dynamically based on screen height
          right: screenWidth * 0.05, // Adjust dynamically based on screen width
          child: ElevatedButton(
            onPressed: () {
              _navigateToChildLogin(context);
            },
            child: Text(
              "Child Login",
              style: TextStyle(fontSize: 18), // Smaller text for better fit
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<String?> _googleSignIn(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'https://www.googleapis.com/auth/contacts.readonly',
          "https://www.googleapis.com/auth/userinfo.profile"
        ],
      );
      await googleSignIn.signOut();

      GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser != null) {
        print("Google User: ${googleUser.email}"); // Debugging step

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
        print(
            "Google SignIn successful: ${userCredential.user!.email}"); // Debugging step
        return null; // Return null to indicate success
      }
      print("Google Sign-In cancelled or failed");
      return "Google Sign-In cancelled or failed"; // Return error message if Google sign-in is canceled
    } catch (e) {
      print("Oops! Google SignIn failed: $e");
      return "Oops! Google SignIn failed: $e"; // Return error message if an exception occurs
    }
  }

  // Navigate to child login page
  void _navigateToChildLogin(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChildLoginPage()),
    );
  }
}

class AdditionalInfoScreen extends StatefulWidget {
  final User user;
  final AuthService auth;

  AdditionalInfoScreen({required this.user, required this.auth});

  @override
  _AdditionalInfoScreenState createState() => _AdditionalInfoScreenState();
}

class _AdditionalInfoScreenState extends State<AdditionalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _firstName;
  String? _lastName;
  String? _username;

  Future<String> _registerParentforProviderLogin(String email,
      String? firstname, String? lastname, String? username) async {
    try {
      await widget.auth
          .registerParent(username!, firstname!, lastname!, email, null, false);
      return "Additional information saved successfully";
    } on UsernameAlreadyExistsException {
      return "Username already exists";
    } catch (e) {
      print("Error: $e");
      return "Registration failed";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Additional Information')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'First Name'),
                onSaved: (value) => _firstName = value,
                validator: (value) => value == null || value.isEmpty
                    ? 'First name is required'
                    : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Last Name'),
                onSaved: (value) => _lastName = value,
                validator: (value) => value == null || value.isEmpty
                    ? 'Last name is required'
                    : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Username'),
                onSaved: (value) => _username = value,
                validator: (value) => value == null || value.isEmpty
                    ? 'Username is required'
                    : null,
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    /*
                    final encryptedParentInfo = await encryptParentInfoWithIV(
                      widget.user.uid,
                      _username!,
                      widget.user.email!,
                      _firstName ?? '',
                      _lastName ?? '',
                    );*/

                    // Save additional information to the database
                    String result = await _registerParentforProviderLogin(
                      widget.user.email!,
                      _firstName ?? '',
                      _lastName ?? '',
                      _username ?? '',
                    );

                    //        await widget.auth.postParentLogin(widget.user!);
                    // Show a snackbar with the result
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result)),
                    );

                    if (result == "Additional information saved successfully") {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => ParentBasePage(),
                        ),
                      );
                    }
                  }
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
