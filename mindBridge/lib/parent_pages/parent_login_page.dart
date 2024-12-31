import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart'; // For Google sign-in
import 'package:test_app/parent_pages/privacy_policy.dart';
import 'package:test_app/parent_pages/terms_of_use.dart';
import 'package:test_app/security.dart';

import '../auth_logic.dart';
import '../child_pages/child_login_page.dart';
import '../main.dart';
import 'package:test_app/authExceptions.dart';
import 'package:test_app/widgets/parent_provider.dart'; // Adjust the path as necessary
import 'package:provider/provider.dart'; // Add this line
import 'package:test_app/parent_pages/parent_login_widget.dart';

class ParentLoginPage extends StatelessWidget {
  ParentLoginPage({super.key});

  final AuthService _auth = AuthService();
  bool isLoading = false; // Add a state to track loading status

  void _startLoading(BuildContext context) {
    isLoading = true;
    // Trigger a rebuild to show loading changes
    (context as Element).markNeedsBuild();
  }

  void _stopLoading(BuildContext context) {
    isLoading = false;
    // Trigger a rebuild to hide loading changes
    (context as Element).markNeedsBuild();
  }

  Future<String?> _authUser(LoginData data, BuildContext context) async {
    _startLoading(context); // Start loading when login starts

    try {
      print("ParentLoginPage: _authUser: ${data.name}, ${data.password}");
      await _auth.signInParentwithEmailandPassword(
          data.name, data.password, context);
    } on UserNotParentException {
      return 'User is not a parent';
    } on ParentDoesNotExistException {
      return 'Username or password is incorrect';
    } on EmailNotVerifiedException {
      return 'Email not verified. Please verify your email before signing in.';
    } on FirebaseAuthException catch (e) {
      if (e.toString().contains('The email address is badly formatted')) {
        return 'Username or password is incorrect';
      } else if (e.toString().contains('auth credential is incorrect')) {
        return 'Username or password is incorrect';
      }
      print("Unexpected error: $e");
      return e.toString();
    } catch (e) {
      if (e.toString().contains('The email address is badly formatted')) {
        return 'Username or password is incorrect';
      } else if (e.toString().contains('auth credential is incorrect')) {
        return 'Username or password is incorrect';
      }
      print("Unexpected error: $e");
      return e.toString();
    } finally {
      _stopLoading(context); // Stop loading when login ends
    }
    await Future.delayed(const Duration(seconds: 1));
    return null;
  }

  Future<String?> _recoverPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return 'Email sent. Please check your email to reset your password.';
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
      print("Email: ${data.name}");
      print("Password: ${data.password}");
      print("First Name: ${data.additionalSignupData?["First name"]}");
      print("Last Name: ${data.additionalSignupData?["Last name"]}");
      print("Username: ${data.additionalSignupData?["Username"]}");

      // Validate required additional signup fields
      if ((data.additionalSignupData?["First name"]?.isEmpty ?? true) ||
          (data.additionalSignupData?["Last name"]?.isEmpty ?? true) ||
          (data.additionalSignupData?["Username"]?.isEmpty ?? true)) {
        return "All fields are required.";
      }

      // Call your registerParent method
      await _auth.registerParent(
        data.additionalSignupData?["Username"] ?? '',
        data.additionalSignupData?["First name"] ?? '',
        data.additionalSignupData?["Last name"] ?? '',
        data.name!, // For email address
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
        return "Registration failed: The email address is already in use by another account";
      }
      print("Unexpected error: $e");
      return "Registration failed";
    }

    return 'Registration successful! Please check your email to activate your account'; // Registration successful
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return MouseRegion(
      cursor: isLoading
          ? SystemMouseCursors.progress
          : SystemMouseCursors.basic, // Change cursor based on loading state
      child: AbsorbPointer(
        absorbing: isLoading, // Prevent user interactions during loading
        child: Container(
          color: Colors
              .lightBlue[50], // Light blue background for the entire screen
          child: Stack(
            children: [
              Center(
                child: Stack(
                  children: [
                    VoxigoLoginWidget(
                      privacyPolicy: PrivacyPolicyPage(),
                      termsOfService: TermsOfUsePage(),
                      onLogin: (email, password) => _authUser(
                          LoginData(name: email, password: password), context),
                      onSignup: (email, password, additionalSignupData) async {
                        _startLoading(context); // Start loading on signup
                        try {
                          final signupResult = await _signUp(
                            SignupData(
                              name: email,
                              password: password,
                              additionalSignupData:
                                  additionalSignupData, // Pass additional fields
                            ),
                          );
                          return signupResult;
                        } finally {
                          _stopLoading(context); // Stop loading after signup
                        }
                      },
                      onRecoverPassword: (email) async {
                        _startLoading(
                            context); // Start loading on recover password
                        try {
                          final recoverResult = await _recoverPassword(email);
                          return recoverResult;
                        } finally {
                          _stopLoading(
                              context); // Stop loading after recover password
                        }
                      },
                      footer: "Voxigo",
                      messages: LoginMessages(
                        recoverPasswordIntro:
                            'Please enter the email address associated with your account.',
                        recoverPasswordDescription:
                            'We will send you a link to reset your password.',
                      ),
                      savedEmail: '',
                      savedPassword: '',
                      additionalSignupFields: [
                        UserFormField(keyName: "First name"),
                        UserFormField(keyName: "Last name"),
                        UserFormField(keyName: "Username"),
                      ],
                      title: "Parent Login",
                      theme: LoginTheme(primaryColor: Color(0xFF56B1FB)),
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
                      loginAfterSignUp: true,
                      redirectAfterSignup: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (context) => ParentLoginPage()),
                        );
                      },
                      redirectAfterRecoverPassword: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (context) => ParentLoginPage()),
                        );
                      },
                      onGoogleSignIn: () async {
                        final googleSignInResult = await _googleSignIn(context);
                        return googleSignInResult;
                      },
                      onSubmitAnimationCompleted: () async {
                        User? user = FirebaseAuth.instance.currentUser;

                        if (user != null) {
                          print("ParentLoginPage: _authUser: ${user.email}");

                          if (user.emailVerified == false) {
                            await user.sendEmailVerification();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Email verification sent. Please verify your email before signing in.'),
                              ),
                            );
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                  builder: (context) => ParentLoginPage()),
                            );
                            return;
                          }

                          await _auth.postParentLogin(user);

                          ParentProvider parentProvider =
                              Provider.of<ParentProvider>(context,
                                  listen: false);

                          await parentProvider.fetchParentData(user.uid);

                          bool checkAdditionalInfo =
                              await _auth.checkAdditionalInfo(user.email!,
                                  user.uid, parentProvider.parentData);

                          bool needsAdditionalInfo;

                          if (checkAdditionalInfo == true) {
                            needsAdditionalInfo = false;
                          } else {
                            needsAdditionalInfo = true;
                          }

                          if (needsAdditionalInfo) {
                            Navigator.of(context)
                                .pushReplacement(MaterialPageRoute(
                              builder: (context) =>
                                  AdditionalInfoScreen(user: user, auth: _auth),
                            ));
                          } else {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                  builder: (context) => ParentBasePage()),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Authentication failed. Please try again.')),
                          );
                        }
                      },
                    ),
                    if (isLoading) // Display loading indicator if loading
                      Center(
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
              Positioned(
                top: screenHeight *
                    0.05, // Adjust dynamically based on screen height
                right: screenWidth *
                    0.05, // Adjust dynamically based on screen width
                child: ElevatedButton(
                  onPressed: () {
                    _navigateToChildLogin(context);
                  },
                  child: Text(
                    "Child Login",
                    style: TextStyle(
                        fontSize: 18,
                        color:
                            Colors.blueAccent), // Smaller text for better fit
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
        return "Google SignIn successful"; // Return null to indicate success
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
