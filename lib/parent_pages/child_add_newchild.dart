import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_app/widgets/parent_provider.dart';
import '../auth_logic.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:test_app/authExceptions.dart';
import 'package:test_app/auth_logic.dart';
import 'package:test_app/user_session_management.dart';

class RegisterChildForm extends StatefulWidget {
  const RegisterChildForm({Key? key}) : super(key: key);

  @override
  State<RegisterChildForm> createState() => _RegisterChildPageState();
}

class _RegisterChildPageState extends State<RegisterChildForm> {
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
  bool _isAgreementChecked = false;
  String discliamer = ParentProvider().globaldisclaimer;

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
    if (isSessionValid == false) {
      return SessionExpiredWidget(
        onLogout: () => logOutUser(context),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Child"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, false);
          },
        ),
        elevation: 1,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Add Details",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildField(
                  controller: _usernameController,
                  label: 'Username',
                  hint: 'Enter username',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Username is required';
                    } else if (value.length < 3) {
                      return 'Username must be at least 3 characters long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        controller: _firstNameController,
                        label: 'First Name',
                        hint: 'First Name',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildField(
                        controller: _lastNameController,
                        label: 'Last Name',
                        hint: 'Last Name',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Enter password',
                  obscureText: !_isPasswordVisible,
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    } else if (value.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _confirmPasswordController,
                  label: 'Re-enter Password',
                  hint: 'Confirm password',
                  obscureText: !_isConfirmPasswordVisible,
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    } else if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _isAgreementChecked,
                      onChanged: (value) {
                        setState(() {
                          _isAgreementChecked = value!;
                        });
                      },
                    ),
                    Expanded(
                      child: Text(
                        discliamer,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _isAgreementChecked
                      ? () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            _showLoadingDialog(context);
                            try {
                              User? user = FirebaseAuth.instance.currentUser;
                              await _user.encryptChildDataAndRegister(
                                user!.uid,
                                _firstNameController.text.trim(),
                                _lastNameController.text.trim(),
                                _usernameController.text.trim(),
                                _passwordController.text.trim(),
                                discliamer,
                              );
                              Navigator.pop(context); // Close loading dialog
                              Navigator.pop(context, true); // Return success
                            } on UsernameAlreadyExistsException {
                              Navigator.pop(context); // Close loading dialog
                              showTopSnackBar(
                                Overlay.of(context),
                                CustomSnackBar.error(
                                  backgroundColor: Colors.red.shade900,
                                  message: "Username already exists",
                                ),
                              );
                            } catch (e) {
                              Navigator.pop(context); // Close loading dialog
                              showTopSnackBar(
                                Overlay.of(context),
                                CustomSnackBar.error(
                                  backgroundColor: Colors.red.shade900,
                                  message: "An error occurred",
                                ),
                              );
                            }
                          }
                        }
                      : null,
                  child: const Text(
                    "Add Child",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        suffixIcon: suffixIcon,
      ),
      obscureText: obscureText,
      validator: validator,
      textInputAction: TextInputAction.next,
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
