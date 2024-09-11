import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../auth_logic.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class ParentHomePage extends StatelessWidget {
  const ParentHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(children: [
      ElevatedButton(
        onPressed: () {
          _showFormDialog(context);
        },
        child: Text("Add Child"),
      )
    ]));
  }

  void _showFormDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RegisterChildDialog();
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
      child:
          Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: FormBuilderTextField(
            name: 'Username',
            decoration: const InputDecoration(labelText: 'Username'),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.username(),
            ]),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: FormBuilderTextField(
            name: 'First name',
            decoration: const InputDecoration(labelText: 'First name'),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.firstName(),
              FormBuilderValidators.required(),
            ]),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: FormBuilderTextField(
            name: 'Last name',
            decoration: const InputDecoration(labelText: 'Last name'),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.lastName(),
              FormBuilderValidators.required(),
            ]),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: FormBuilderTextField(
            name: 'Password',
            decoration: const InputDecoration(labelText: 'Password'),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
              FormBuilderValidators.password(),
            ]),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 8),
          child: Row(children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    debugPrint(_formKey.currentState?.instantValue.toString());
                    User? user = FirebaseAuth.instance.currentUser;
                    try{
                      await _user.registerChild(
                          user!.uid,
                          _formKey.currentState?.instantValue['First name'],
                          _formKey.currentState?.instantValue['Last name'],
                          _formKey.currentState?.instantValue['Username'],
                          _formKey.currentState?.instantValue['Password']);
                      Navigator.pop(context);
                      showTopSnackBar(Overlay.of(context),
                        CustomSnackBar.success(
                          backgroundColor: Colors.green,
                          message: "Child has been added",
                        ),
                        displayDuration: Duration(seconds: 3),
                      );
                    } on UsernameAlreadyExistsException{
                      showTopSnackBar(Overlay.of(context),
                        CustomSnackBar.error(
                          backgroundColor: Colors.red.shade900,
                          message: "Username already exists",
                        ),
                        displayDuration: Duration(seconds: 3),
                      );
                    }

                  }
                },
                child: const Text('Register Child'),
              ),
            ),
          ]),
        )
      ]),
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
            minHeight: 300, // Minimum height of the dialog
            maxHeight: MediaQuery.of(context).size.height * 0.9, // Max height
          ),
          child: IntrinsicHeight(child: RegisterChildForm())),
      title: Text("Add a child"),
    );
  }
}

final childSuccessSnackBar = SnackBar(
    content: Text('Child has been added'),
    behavior: SnackBarBehavior.floating,
    margin: EdgeInsets.only(top: 10, left: 10.0, right: 10.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(0),
    ),
    backgroundColor: Colors.green,
    duration: Duration(seconds: 3));
