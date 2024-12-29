import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_app/cache_utility.dart';
import 'package:test_app/getauthtokenandkey.dart';
import '../auth_logic.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:test_app/authExceptions.dart';
import 'package:test_app/security.dart';

import '../child_pages/home_page.dart';
import '../widgets/child_provider.dart';
import '../widgets/theme_provider.dart';

class ResetPasswordForm extends StatefulWidget {
  const ResetPasswordForm({super.key});

  @override
  State<ResetPasswordForm> createState() => _ResetPasswordFormState();
}

class _ResetPasswordFormState extends State<ResetPasswordForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Email Field
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email is required';
                }
                final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                if (!emailRegex.hasMatch(value)) {
                  return 'Enter a valid email address';
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
                          final email = _emailController.text.trim();

                          // Perform password reset
                          await _resetPassword(email);

                          // Success Handling
                          Navigator.pop(context); // Close loading dialog
                          Navigator.pop(context); // Close form dialog
                          showTopSnackBar(
                            Overlay.of(context),
                            CustomSnackBar.success(
                              backgroundColor: Colors.green,
                              message: "A reset link has been sent to $email",
                            ),
                            displayDuration: const Duration(seconds: 3),
                          );

                          // Log out the user
                          _logoutUser(context);
                        } catch (e) {
                          // Error Handling
                          Navigator.pop(context); // Close loading dialog
                          showTopSnackBar(
                            Overlay.of(context),
                            CustomSnackBar.error(
                              backgroundColor: Colors.red.shade900,
                              message: "Error: $e",
                            ),
                            displayDuration: const Duration(seconds: 3),
                          );
                        }
                      }
                    },
                    child: const Text("Reset Password"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPassword(String email) async {
    // Call Firebase method to reset password
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  void _logoutUser(BuildContext context) async {
    logOutUser(context);
    Navigator.of(context).pushReplacementNamed('/parent_login');
    print("User logged out");
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

class ResetPasswordDialog extends StatelessWidget {
  const ResetPasswordDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Container(
        width: 500,
        constraints: BoxConstraints(
          minHeight: 150,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: IntrinsicHeight(child: ResetPasswordForm()),
      ),
      title: const Text("Change Password"),
    );
  }
}
