import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart'; // Add this line
import 'package:google_sign_in/google_sign_in.dart'; // For Google sign-in
import 'package:test_app/parent_pages/privacy_policy.dart';
import 'package:test_app/parent_pages/terms_of_use.dart';
import 'package:test_app/security.dart';
import 'package:test_app/user_session_management.dart';

import '../auth_logic.dart';
import '../child_pages/child_login_page.dart';
import '../main.dart';
import 'package:test_app/authExceptions.dart';
import 'package:test_app/widgets/parent_provider.dart'; // Adjust the path as necessary
import 'package:provider/provider.dart'; // Add this line
import 'package:flutter/gestures.dart'; // Add this line
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
    FocusScope.of(context).unfocus();

    _startLoading(context); // Start loading when login starts
    await logOutUser(context);
    try {
      print("ParentLoginPage: _authUser: ${data.name}, ${data.password}");
      await _auth.signInParentwithEmailandPassword(
          data.name, data.password, context);
      isSessionValid = true;
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
      isSessionValid = true;
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

    return GestureDetector(
      onTap: () {
        // Hide the keyboard when tapping outside controls
        FocusScope.of(context).unfocus();
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      },
      child: MouseRegion(
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
                            LoginData(name: email, password: password),
                            context),
                        onSignup:
                            (email, password, additionalSignupData) async {
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
                          final googleSignInResult =
                              await _googleSignIn(context);
                          return googleSignInResult;
                        },
                        onSubmitAnimationCompleted: () async {
                          User? user = FirebaseAuth.instance.currentUser;

                          if (user == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Authentication failed. Please try again.'),
                              ),
                            );
                            return; // Stop execution if no user is signed in
                          }

                          print("ParentLoginPage: _authUser: ${user.email}");

// Check if email is verified
                          if (!user.emailVerified) {
                            try {
                              await user.sendEmailVerification();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Email verification sent. Please verify your email before signing in.',
                                  ),
                                ),
                              );
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => ParentLoginPage(),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Failed to send verification email: $e'),
                                ),
                              );
                            }
                            isSessionValid = false;

                            return; // Stop execution for unverified email
                          }

// Call server to log in the parent
                          try {
                            await _auth.postParentLogin(user);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Login process failed: $e'),
                              ),
                            );
                            isSessionValid = false;

                            return; // Stop execution if server login fails
                          }

// Fetch parent data
                          ParentProvider parentProvider =
                              Provider.of<ParentProvider>(context,
                                  listen: false);
                          try {
                            await parentProvider.fetchParentData(user.uid);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to fetch user data: $e'),
                              ),
                            );
                            isSessionValid = false;

                            return; // Stop execution if parent data fetch fails
                          }

// Check additional information
                          bool needsAdditionalInfo = true;
                          try {
                            bool checkAdditionalInfo =
                                await _auth.checkAdditionalInfo(
                              user.email!,
                              user.uid,
                              parentProvider.parentData,
                            );

                            needsAdditionalInfo = !checkAdditionalInfo;
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Error checking additional information: $e'),
                              ),
                            );
                            isSessionValid = false;

                            return; // Stop execution if additional info check fails
                          }

// Redirect based on additional info requirement
                          if (needsAdditionalInfo) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => AdditionalInfoScreen(
                                    user: user, auth: _auth),
                              ),
                            );
                          } else {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => ParentBasePage(),
                              ),
                            );
                          }
                        }, // on submit animation completed
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
      ),
    );
  }

  Future<String?> _googleSignIn(BuildContext context) async {
    try {
      // Logout any existing session
      await logOutUser(context);

      // Initialize Google Sign-In with minimal scope
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
      await googleSignIn.signOut();

      // Start Google Sign-In flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception("Google Sign-In cancelled by user");
      }

      // Obtain authentication tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      if (googleAuth.idToken == null || googleAuth.accessToken == null) {
        throw Exception("Invalid Google Authentication tokens");
      }

      // Create Firebase credentials
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with Firebase and validate user
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null ||
          firebaseUser.email == null ||
          firebaseUser.uid.isEmpty) {
        throw Exception(
            "Firebase authentication failed or user data is incomplete");
      }

      // Ensure session is secure and consistent
      isSessionValid = true;
      setUserSessionActive(firebaseUser.uid);
      listenToUserSession(firebaseUser.uid);

      print("Google Sign-In successful: ${firebaseUser.email}");
      return "Google Sign-In successful";
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException: ${e.message}");
      return "Authentication error: ${e.message}";
    } on Exception catch (e) {
      print("General Exception during Google Sign-In: $e");
      return "Oops! Something went wrong during sign-in: $e";
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
  bool _isTermsAccepted = false;

  Future<String> _registerParentForProviderLogin(
      String email, String? firstname, String? lastname) async {
    try {
      await widget.auth
          .registerParent('voxigo', firstname!, lastname!, email, null, false);

      ParentProvider parentProvider =
          Provider.of<ParentProvider>(context, listen: false);

      parentProvider.parentData.firstname = firstname;
      parentProvider.parentData.lastname = lastname;

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
    final isCompact = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('Additional Information'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'First Name'),
                  onSaved: (value) => _firstName = value,
                  validator: (value) => value == null || value.isEmpty
                      ? 'First name is required'
                      : null,
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Last Name'),
                  onSaved: (value) => _lastName = value,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Last name is required'
                      : null,
                ),
                SizedBox(height: 24.0),
                Row(
                  children: [
                    Checkbox(
                      value: _isTermsAccepted,
                      onChanged: (value) {
                        setState(() {
                          _isTermsAccepted = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: RichText(
                        textAlign: TextAlign.start,
                        text: TextSpan(
                          text: "I have read and accepted Voxigo's ",
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: isCompact ? 12.0 : 14.0,
                          ),
                          children: [
                            TextSpan(
                              text: "Terms of Service",
                              style: const TextStyle(
                                color: Color(0xFF56B1FB),
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.pushNamed(context, '/terms_of_use');
                                },
                            ),
                            const TextSpan(text: " and "),
                            TextSpan(
                              text: "Privacy Policy",
                              style: const TextStyle(
                                color: Color(0xFF56B1FB),
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.pushNamed(
                                      context, '/privacy_policy');
                                },
                            ),
                            const TextSpan(text: "."),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.0),
                ElevatedButton(
                  onPressed: _isTermsAccepted
                      ? () async {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            String result =
                                await _registerParentForProviderLogin(
                              widget.user.email!,
                              _firstName ?? '',
                              _lastName ?? '',
                            );

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(result)),
                            );

                            if (result ==
                                "Additional information saved successfully") {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => ParentBasePage(),
                                ),
                              );
                            }
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF56B1FB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: isCompact ? 12.0 : 16.0,
                    ),
                  ),
                  child: Text(
                    'Submit',
                    style: TextStyle(
                      fontSize: isCompact ? 18.0 : 20.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
