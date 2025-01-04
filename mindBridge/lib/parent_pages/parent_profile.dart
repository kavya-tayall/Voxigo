import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_app/security.dart';
import 'package:test_app/widgets/parent_provider.dart';
import 'package:provider/provider.dart';

class EditAndViewProfileForm extends StatefulWidget {
  final String userid;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final bool isEditMode;

  const EditAndViewProfileForm({
    super.key,
    required this.userid,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.isEditMode = false,
  });

  @override
  State<EditAndViewProfileForm> createState() => _EditAndViewProfileFormState();
}

class _EditAndViewProfileFormState extends State<EditAndViewProfileForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  //late final TextEditingController _usernameController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late bool _isEditMode;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    //  _usernameController = TextEditingController(text: widget.username);
    _firstNameController = TextEditingController(text: widget.firstName);
    _lastNameController = TextEditingController(text: widget.lastName);
    _isEditMode = widget.isEditMode;
  }

  @override
  void dispose() {
    // _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      _showLoadingDialog();

      try {
        // Simulate save profile logic
        final encryptedParentInfo = await encryptParentInfoWithIV(
          widget.userid,
          'voxigo',
          widget.email,
          _firstNameController.text,
          _lastNameController.text,
        );
        // Save user details in Firestore
        print('useerid: ${widget.userid}');
        try {
          await _db.collection('parents').doc(widget.userid).update({
            'username': encryptedParentInfo['username'],
            'firstname': encryptedParentInfo['firstname'],
            'lastname': encryptedParentInfo['lastname'],
            'email': encryptedParentInfo['email'],
            'iv': encryptedParentInfo['iv'],
          });
          print('Parent details updated successfully.');
        } catch (e) {
          if (e is FirebaseException && e.code == 'not-found') {
            // Document doesn't exist, consider creating it instead
            print('Parent not found. ');
          } else {
            // Handle other errors
            print('Failed to parent  details: $e');
            rethrow; // Rethrow the error if needed
          }
        }

        ParentProvider parentProvider =
            Provider.of<ParentProvider>(context, listen: false);
        parentProvider.updateParentData(
          username: 'voxigo',
          firstname: _firstNameController.text,
          lastname: _lastNameController.text,
        );

        Navigator.pop(context); // Close loading dialog
        Navigator.pop(context); // Close form dialog
        setState(() {
          _isEditMode = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      } catch (e) {
        Navigator.pop(context); // Close loading dialog
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
            // Email Field (Read-Only)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextFormField(
                initialValue: widget.email,
                readOnly: true, // Ensures the field cannot be edited
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: const OutlineInputBorder(),
                  enabled: false, // Makes the field look visually disabled
                ),
                style: TextStyle(
                  color: Theme.of(context)
                      .disabledColor, // Optional: Matches disabled text color
                ),
              ),
            ),
            // Username Field
            /*
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextFormField(
                controller: _usernameController,
                enabled: _isEditMode,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Username is required';
                  }
                  return null;
                },
              ),
            ),*/
            // First Name Field
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextFormField(
                controller: _firstNameController,
                enabled: _isEditMode,
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
                enabled: _isEditMode,
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
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isEditMode ? _saveProfile : _toggleEditMode,
                    child: Text(_isEditMode ? 'Save' : 'Edit'),
                  ),
                ),
                if (_isEditMode) const SizedBox(width: 8.0),
                if (_isEditMode)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => _isEditMode = false),
                      child: const Text('Cancel'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EditProfileDialog extends StatelessWidget {
  final String userid;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final bool isEditMode;

  const EditProfileDialog({
    super.key,
    required this.userid,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.isEditMode = false, // Default is view mode
  });

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
          child: EditAndViewProfileForm(
            userid: userid,
            username: username,
            firstName: firstName,
            lastName: lastName,
            email: email,
            isEditMode: isEditMode, // Pass the initial mode
          ),
        ),
      ),
      title: const Text("Edit Profile"),
    );
  }
}
