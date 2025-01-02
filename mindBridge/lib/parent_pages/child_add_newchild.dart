import 'package:flutter/material.dart';
import '../auth_logic.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:test_app/authExceptions.dart';

class RegisterChildForm extends StatefulWidget {
  const RegisterChildForm({super.key});

  @override
  State<RegisterChildForm> createState() => _RegisterChildFormState();
}

class _RegisterChildFormState extends State<RegisterChildForm> {
  final UserService _user = UserService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Username Field
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Username is required';
                } else if (value.length < 3) {
                  return 'Username must be at least 3 characters long';
                }
                return null;
              },
            ),
          ),
          // First Name Field
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'First Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'First Name is required';
                }
                return null;
              },
            ),
          ),
          // Last Name Field
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Last Name is required';
                }
                return null;
              },
            ),
          ),
          // Password Field
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
              obscureText: !_isPasswordVisible,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                } else if (value.length < 6) {
                  return 'Password must be at least 6 characters long';
                }
                return null;
              },
            ),
          ),
          // Re-enter Password Field
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Re-enter Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                ),
              ),
              obscureText: !_isConfirmPasswordVisible,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                } else if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ),
          // Submit Button
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        _showLoadingDialog(context);
                        try {
                          User? user = FirebaseAuth.instance.currentUser;
                          String newChildId =
                              await _user.encryptChildDataAndRegister(
                            user!.uid,
                            _firstNameController.text.trim(),
                            _lastNameController.text.trim(),
                            _usernameController.text.trim(),
                            _passwordController.text.trim(),
                          );
                          print('New child ID: $newChildId');
                          // Success Handling
                          Navigator.pop(context); // Close loading dialog
                          Navigator.pop(context); // Close form dialog
                          showTopSnackBar(
                            Overlay.of(context),
                            CustomSnackBar.success(
                              backgroundColor: Colors.green,
                              message: "Child has been added",
                            ),
                            displayDuration: const Duration(seconds: 3),
                          );
                        } on UsernameAlreadyExistsException {
                          // Error Handling
                          Navigator.pop(context); // Close loading dialog
                          showTopSnackBar(
                            Overlay.of(context),
                            CustomSnackBar.error(
                              backgroundColor: Colors.red.shade900,
                              message: "Username already exists",
                            ),
                            displayDuration: const Duration(seconds: 3),
                          );
                        }
                      }
                    },
                    child: const Text("Register Child"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}

class RegisterChildDialog extends StatelessWidget {
  const RegisterChildDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Container(
          width: 500,
          constraints: BoxConstraints(
            minHeight: 300,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: IntrinsicHeight(child: RegisterChildForm())),
      title: Text("Add a child"),
    );
  }
}
