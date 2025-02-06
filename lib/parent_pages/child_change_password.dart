import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_app/auth_logic.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bcrypt/bcrypt.dart';

class ChangeChildPasswordForm extends StatefulWidget {
  final String parentId;
  final String childId;
  final String username;
  final String firstName;
  final String lastName;
  final Function(bool) onParentAuthenticated;

  const ChangeChildPasswordForm({
    super.key,
    required this.parentId,
    required this.childId,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.onParentAuthenticated,
  });

  @override
  State<ChangeChildPasswordForm> createState() =>
      _ChangeChildPasswordFormState();
}

class _ChangeChildPasswordFormState extends State<ChangeChildPasswordForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _parentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  bool _isParentAuthenticated =
      true; // set to true to supress parent password validation
  bool _showParentPassword = false;
  bool _showChildPassword = false;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void dispose() {
    _parentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _validateParentPassword() async {
    if (_parentPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your password.')),
      );
      return;
    }

    try {
      // Simulating validation logic
      bool isValid = await validateParentPassword(
        widget.parentId,
        _parentPasswordController.text,
      );
      if (isValid) {
        widget.onParentAuthenticated(true); // Notify the dialog
        setState(() {
          _isParentAuthenticated = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password validated.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid password. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error validating password: $e')),
      );
    }
  }

  Future<void> _changeChildPassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      _showLoadingDialog();

      try {
        final String hashedPassword =
            BCrypt.hashpw(_newPasswordController.text, BCrypt.gensalt());

        await _db.collection('children').doc(widget.childId).update({
          'password': hashedPassword,
        });

        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully!')),
        );
        Navigator.pop(context); // Close the form dialog
      } catch (e) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating password: $e')),
        );
      }
    }
  }

  void _showLoadingDialog() {
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

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isParentAuthenticated)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _parentPasswordController,
                    obscureText: !_showParentPassword,
                    decoration: InputDecoration(
                      labelText: 'Parent Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showParentPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _showParentPassword = !_showParentPassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  ElevatedButton(
                    onPressed: _validateParentPassword,
                    child: const Text('Validate Password'),
                  ),
                ],
              ),
            if (_isParentAuthenticated)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16.0),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 2,
                    margin: const EdgeInsets.all(8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Username:',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              Text(widget.username,
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('First Name:',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              Text(widget.firstName,
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Last Name:',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              Text(widget.lastName,
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: !_showChildPassword,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showChildPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _showChildPassword = !_showChildPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a new password.';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters long.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: _changeChildPassword,
                    child: const Text('Change Password'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class ChangeChildPasswordDialog extends StatefulWidget {
  final String parentId;
  final String childId;
  final String username;
  final String firstName;
  final String lastName;

  const ChangeChildPasswordDialog({
    super.key,
    required this.parentId,
    required this.childId,
    required this.username,
    required this.firstName,
    required this.lastName,
  });

  @override
  State<ChangeChildPasswordDialog> createState() =>
      _ChangeChildPasswordDialogState();
}

class _ChangeChildPasswordDialogState extends State<ChangeChildPasswordDialog> {
  bool _isParentAuthenticated = true; //false;

  void _updateParentAuthentication(bool isAuthenticated) {
    setState(() {
      _isParentAuthenticated = true; //isAuthenticated;
    });
  }

  String _getDialogTitle() {
    return _isParentAuthenticated
        ? 'Change Child Password'
        : 'Enter Parent Password to Change Password';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_getDialogTitle()),
      content: Container(
        width: 600,
        constraints: BoxConstraints(
          minHeight: 300,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: IntrinsicHeight(
          child: ChangeChildPasswordForm(
            parentId: widget.parentId,
            childId: widget.childId,
            username: widget.username,
            firstName: widget.firstName,
            lastName: widget.lastName,
            // Callback to update parent authentication state
            onParentAuthenticated: _updateParentAuthentication,
          ),
        ),
      ),
    );
  }
}
