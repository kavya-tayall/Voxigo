import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_app/auth_logic.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeleteAccountForm extends StatefulWidget {
  final String parentId;
  final Function(bool) onParentAuthenticated;

  const DeleteAccountForm({
    super.key,
    required this.parentId,
    required this.onParentAuthenticated,
  });

  @override
  State<DeleteAccountForm> createState() => _DeleteAccountFormState();
}

class _DeleteAccountFormState extends State<DeleteAccountForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _parentPasswordController =
      TextEditingController();
  final TextEditingController _confirmationController = TextEditingController();
  final UserService _user = UserService();

  bool _isParentAuthenticated = false;
  bool _showParentPassword = false;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void dispose() {
    _parentPasswordController.dispose();
    _confirmationController.dispose();
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
      bool isValid = await validateParentPassword(
        widget.parentId,
        _parentPasswordController.text,
      );
      if (isValid) {
        widget.onParentAuthenticated(true);
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

  Future<void> _deleteAccount() async {
    if (_confirmationController.text.toUpperCase() != 'AGREE') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must type "AGREE" to confirm.')),
      );
      return;
    }

    _showLoadingDialog();

    try {
      await _user.deleteParentAccount();

      Navigator.pop(context); // Close the loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted successfully!')),
      );
      Navigator.pop(context); // Close the form dialog
    } catch (e) {
      Navigator.pop(context); // Close the loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting account: $e')),
      );
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
                  Text(
                    'This action will delete your account and all child accounts associated with it. '
                    'Data uploaded or saved in these accounts will also be permanently deleted. '
                    'This action cannot be undone.',
                    style: TextStyle(color: Colors.red, fontSize: 14.0),
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _confirmationController,
                    decoration: const InputDecoration(
                      labelText: 'Type "AGREE" to confirm',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: _deleteAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Delete Account'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class DeleteAccountDialog extends StatefulWidget {
  final String parentId;

  const DeleteAccountDialog({
    super.key,
    required this.parentId,
  });

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  bool _isParentAuthenticated = false;

  void _updateParentAuthentication(bool isAuthenticated) {
    setState(() {
      _isParentAuthenticated = isAuthenticated;
    });
  }

  String _getDialogTitle() {
    return _isParentAuthenticated
        ? 'Delete Account'
        : 'Enter Parent Password to Proceed';
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
          child: DeleteAccountForm(
            parentId: widget.parentId,
            onParentAuthenticated: _updateParentAuthentication,
          ),
        ),
      ),
    );
  }
}
