import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../auth_logic.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:test_app/authExceptions.dart';

class ParentSettingsPage extends StatelessWidget {
  const ParentSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/parent_login');
            }),
        ],
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              _showFormDialog(context);
            },
            child: const Text("Add Child"),
          ),
        ],
      ),
    );
  }

  void _showFormDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const RegisterChildDialog();
      },
    );
  }
}

class RegisterChildForm extends StatelessWidget {
  RegisterChildForm({super.key});

  final UserService _user = UserService();
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FormBuilderTextField(
              name: 'Username',
              decoration: const InputDecoration(labelText: 'Username'),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
                FormBuilderValidators.minLength(3),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: FormBuilderTextField(
              name: 'First name',
              decoration: const InputDecoration(labelText: 'First name'),
              validator: FormBuilderValidators.required(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: FormBuilderTextField(
              name: 'Last name',
              decoration: const InputDecoration(labelText: 'Last name'),
              validator: FormBuilderValidators.required(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: FormBuilderTextField(
              name: 'Password',
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
                FormBuilderValidators.minLength(6),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        debugPrint(
                            _formKey.currentState?.instantValue.toString());
                        User? user = FirebaseAuth.instance.currentUser;

                        _showLoadingDialog(context);
                        try {
                          await _user.registerChild(
                            user!.uid,
                            _formKey.currentState?.instantValue['First name'],
                            _formKey.currentState?.instantValue['Last name'],
                            _formKey.currentState?.instantValue['Username'],
                            _formKey.currentState?.instantValue['Password'],
                          );

                          Navigator.pop(context); // Close loading dialog
                          Navigator.pop(context); // Close form dialog

                          showTopSnackBar(
                            Overlay.of(context),
                            const CustomSnackBar.success(
                              backgroundColor: Colors.green,
                              message: "Child has been added",
                            ),
                            displayDuration: const Duration(seconds: 3),
                          );
                        } on UsernameAlreadyExistsException {
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
                    child: const Text('Register Child'),
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
        child: IntrinsicHeight(
          child: RegisterChildForm(),
        ),
      ),
      title: const Text("Add a child"),
    );
  }
}
