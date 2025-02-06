import 'package:flutter/material.dart';

import '../auth_logic.dart';

import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:test_app/auth_logic.dart';
import 'package:test_app/user_session_management.dart';

class DeleteChildForm extends StatefulWidget {
  const DeleteChildForm({super.key});

  @override
  State<DeleteChildForm> createState() => _DeleteChildFormState();
}

class _DeleteChildFormState extends State<DeleteChildForm> {
  final UserService _user = UserService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isSessionValid == false) {
      return SessionExpiredWidget(
        onLogout: () => logOutUser(context),
      );
    }
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
                labelText: 'Child Username',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Username is required';
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
                          final username = _usernameController.text.trim();

                          // Confirm deletion
                          bool confirm = await _showConfirmationDialog(context);
                          if (!confirm) {
                            Navigator.pop(context); // Close loading dialog
                            return;
                          }

                          // Perform deletion
                          await _user.deleteChildByUsername(username);

                          // Success Handling
                          Navigator.pop(context); // Close loading dialog
                          Navigator.pop(context); // Close form dialog
                          showTopSnackBar(
                            Overlay.of(context),
                            CustomSnackBar.success(
                              backgroundColor: Colors.green,
                              message: "Child has been deleted",
                            ),
                            displayDuration: const Duration(seconds: 3),
                          );
                        } catch (e) {
                          // Error Handling
                          Navigator.pop(context); // Close loading dialog
                          showTopSnackBar(
                            Overlay.of(context),
                            CustomSnackBar.error(
                              backgroundColor: Colors.red.shade900,
                              message: "Error deleting child: $e",
                            ),
                            displayDuration: const Duration(seconds: 3),
                          );
                        }
                      }
                    },
                    child: const Text("Delete Child"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Confirm Deletion"),
              content: const Text(
                  "Are you sure you want to delete this child? This action cannot be undone."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Delete"),
                ),
              ],
            );
          },
        ) ??
        false;
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

class DeleteChildDialog extends StatelessWidget {
  const DeleteChildDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Container(
        width: 500,
        constraints: BoxConstraints(
          minHeight: 150,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: IntrinsicHeight(child: DeleteChildForm()),
      ),
      title: Text("Delete a child"),
    );
  }
}
