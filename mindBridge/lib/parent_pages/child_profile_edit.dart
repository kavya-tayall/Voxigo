import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_app/security.dart';
import 'package:test_app/auth_logic.dart';

class EditAndViewChildProfileForm extends StatefulWidget {
  final String parentId;
  final String childId;
  final String username;
  final String firstName;
  final String lastName;
  final String childtheme;
  final bool isEditMode;
  final bool isPasswordRequired;
  final Function(bool) onEditModeChanged;
  final Function(bool) onPasswordRequiredChanged;

  const EditAndViewChildProfileForm({
    super.key,
    required this.parentId,
    required this.childId,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.childtheme,
    required this.onEditModeChanged,
    required this.onPasswordRequiredChanged,
    this.isEditMode = false,
    this.isPasswordRequired = false,
  });

  @override
  State<EditAndViewChildProfileForm> createState() =>
      _EditAndViewChildProfileFormState();
}

class _EditAndViewChildProfileFormState
    extends State<EditAndViewChildProfileForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _usernameController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _passwordController;

  late final FocusNode _usernameFocusNode; // Added focus node

  bool _isPasswordValidated = false;
  late bool _isPasswordRequired;
  late bool _isEditMode;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.username);
    _firstNameController = TextEditingController(text: widget.firstName);
    _lastNameController = TextEditingController(text: widget.lastName);
    _passwordController = TextEditingController();

    _usernameFocusNode = FocusNode(); // Initialize focus node
    _isEditMode = widget.isEditMode;
    _isPasswordRequired = widget.isPasswordRequired;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();

    _usernameFocusNode.dispose(); // Dispose focus node
    super.dispose();
  }

  Future<void> _validateParentPassword() async {
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your password.')),
      );
      return;
    }

    try {
      bool isValid = await validateParentPassword(
        widget.parentId,
        _passwordController.text,
      );
      if (isValid) {
        setState(() {
          print('Password validated');
          _isPasswordValidated = true;
          _isEditMode = true;
          _isPasswordRequired = false;
          Future.delayed(Duration.zero, () {
            _usernameFocusNode.requestFocus(); // Set focus
          });
        });
        widget.onEditModeChanged(true);
        widget.onPasswordRequiredChanged(false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Password validated. You can edit now.')),
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

  Future<void> _saveChildProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      _showLoadingDialog();

      try {
        final encryptedChildInfo = await encryptChildInfoWithIV(
          widget.parentId,
          widget.childId,
          _usernameController.text,
          _firstNameController.text,
          _lastNameController.text,
          widget.childtheme,
          '',
        );

        await _db.collection('children').doc(widget.childId).update({
          'username': encryptedChildInfo['username'],
          'first name': encryptedChildInfo['first name'],
          'last name': encryptedChildInfo['last name'],
          'iv': encryptedChildInfo['iv'],
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Child profile updated successfully!')),
        );
        Navigator.pop(context);
        Navigator.pop(context);
      } catch (e) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
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
            if (!_isPasswordValidated && _isEditMode)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        labelText: 'Parent Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
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
              ),
            if (_isPasswordValidated || !_isEditMode) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextFormField(
                  controller: _usernameController,
                  focusNode: _usernameFocusNode, // Attach focus node
                  enabled: _isEditMode,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextFormField(
                  controller: _firstNameController,
                  enabled: _isEditMode,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextFormField(
                  controller: _lastNameController,
                  enabled: _isEditMode,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
            Row(
              children: [
                if (!_isEditMode)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isEditMode = true;
                          _isPasswordRequired = true;
                          widget.onEditModeChanged(true);
                          widget.onPasswordRequiredChanged(true);
                          Future.delayed(Duration.zero, () {
                            _usernameFocusNode.requestFocus(); // Set focus
                          });
                        });
                      },
                      child: const Text('Edit'),
                    ),
                  ),
                if (_isEditMode && _isPasswordValidated) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveChildProfile,
                      child: const Text('Save'),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isEditMode = false;
                          _isPasswordValidated = false;
                          widget.onEditModeChanged(false);
                          widget.onPasswordRequiredChanged(false);
                        });
                        FocusScope.of(context).unfocus();
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EditChildProfileDialog extends StatefulWidget {
  final String parentId;
  final String childId;
  final String username;
  final String firstName;
  final String lastName;
  final String childtheme;
  final bool isEditMode;

  const EditChildProfileDialog({
    super.key,
    required this.parentId,
    required this.childId,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.childtheme,
    this.isEditMode = false,
  });

  @override
  State<EditChildProfileDialog> createState() => _EditChildProfileDialogState();
}

class _EditChildProfileDialogState extends State<EditChildProfileDialog> {
  late bool _isEditMode;
  late bool _isPasswordRequired;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.isEditMode;
    _isPasswordRequired = widget.isEditMode;
  }

  void _updateEditMode(bool isEditMode) {
    setState(() {
      _isEditMode = isEditMode;
    });
  }

  void _updatePasswordRequired(bool isPasswordRequired) {
    setState(() {
      _isPasswordRequired = isPasswordRequired;
    });
  }

  String _getDialogTitle() {
    if (!_isEditMode) return 'View Child Profile';
    if (_isPasswordRequired) return 'Enter parent password to edit';
    return 'Edit Child Profile';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Container(
        width: 600,
        constraints: BoxConstraints(
          minHeight: 300,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: IntrinsicHeight(
          child: EditAndViewChildProfileForm(
            parentId: widget.parentId,
            childId: widget.childId,
            username: widget.username,
            firstName: widget.firstName,
            lastName: widget.lastName,
            childtheme: widget.childtheme,
            isEditMode: _isEditMode,
            isPasswordRequired: _isPasswordRequired,
            onEditModeChanged: _updateEditMode,
            onPasswordRequiredChanged: _updatePasswordRequired,
          ),
        ),
      ),
      title: Text(_getDialogTitle()),
    );
  }
}
