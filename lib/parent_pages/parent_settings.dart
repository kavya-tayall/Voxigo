import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';
import '../auth_logic.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:test_app/authExceptions.dart';

import '../widgets/child_provider.dart';

class ParentSettingsPage extends StatefulWidget {
  ParentSettingsPage({super.key});

  @override
  State<ParentSettingsPage> createState() => _ParentSettingsPageState();
}

class _ParentSettingsPageState extends State<ParentSettingsPage> {
  String _selectedOption =
      'Select Child'; // Start with an empty selected option
  List<String> childrenNamesList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchChildrenData();
  }

  void _showFormDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RegisterChildDialog();
      },
    );
  }

  Future<void> fetchChildrenData() async {
    try {
      DocumentSnapshot parentSnapshot = await FirebaseFirestore.instance
          .collection('parents')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get();

      if (parentSnapshot.exists) {
        Map<String, dynamic>? parentData =
            parentSnapshot.data() as Map<String, dynamic>?;
        if (parentData != null && parentData['children'] != null) {
          List<dynamic> childrenIDList = parentData['children'];
          for (String childId in childrenIDList) {
            DocumentSnapshot childSnapshot = await FirebaseFirestore.instance
                .collection('children')
                .doc(childId)
                .get();

            if (childSnapshot.exists) {
              Map<String, dynamic>? childData =
                  childSnapshot.data() as Map<String, dynamic>?;
              if (childData != null &&
                  childData['first name'] != null &&
                  childData['last name'] != null) {
                String childName =
                    childData['first name'] + ", " + childData['last name'];
                childrenNamesList.add(childName);
              } else {
                print("no data");
              }
            } else {
              print("dont work");
            }
          }

          setState(() {
            isLoading = false;
            if (childrenNamesList.isNotEmpty) {
              _selectedOption =
                  childrenNamesList[0]; // Set default selected option
            }
          });
        } else {
          print("no data");
        }
      } else {
        print("dont work");
      }
    } catch (e) {
      print('Error fetching selected buttons: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(
            child:
                CircularProgressIndicator()) // Show loading indicator while fetching data
        : SettingsList(
            sections: [
              SettingsSection(
                title: Text('Common'),
                tiles: <SettingsTile>[
                  SettingsTile.navigation(
                    leading: Icon(Icons.language, color: Colors.black),
                    trailing: Text(""),
                    title: Text('Language'),
                    value: Text('English'),
                  ),
                  SettingsTile.switchTile(
                    onToggle: (value) {},
                    initialValue: true,
                    leading: Icon(Icons.format_paint, color: Colors.black),
                    trailing: Text(""),
                    title: Text('Enable custom theme'),
                  ),
                  SettingsTile.navigation(
                    leading: Icon(Icons.logout, color: Colors.black),
                    title: Text('Log out'),
                    trailing: Text(""),
                    onPressed: (context) async {
                      final childProvider =
                          Provider.of<ChildProvider>(context, listen: false);
                      childProvider.logout();
                      await FirebaseAuth.instance.signOut();
                      Navigator.of(context)
                          .pushReplacementNamed('/parent_login');
                    },
                  ),
                ],
              ),
              SettingsSection(
                title: Text('Account'),
                tiles: <SettingsTile>[
                  SettingsTile.navigation(
                    leading: Icon(Icons.person, color: Colors.black),
                    title: Text('Profile'),
                    trailing: Text(""),
                    onPressed: (context) {},
                  ),
                  SettingsTile.navigation(
                    leading: Icon(Icons.lock, color: Colors.black),
                    trailing: Text(""),
                    title: Text('Change Password'),
                    onPressed: (context) {},
                  ),
                  SettingsTile.navigation(
                    leading: Icon(Icons.add, color: Colors.black),
                    trailing: Text(""),
                    title: Text('Add Child'),
                    onPressed: (context) {
                      _showFormDialog(context);
                    },
                  ),
                ],
              ),
              SettingsSection(
                title: Text('Notifications'),
                tiles: <SettingsTile>[
                  SettingsTile.switchTile(
                    leading: Icon(Icons.notifications, color: Colors.black),
                    trailing: Text(""),
                    title: Text('Enable Notifications'),
                    onToggle: (value) {},
                    initialValue: true,
                  ),
                ],
              ),
              SettingsSection(
                title: Text('Privacy'),
                tiles: <SettingsTile>[
                  SettingsTile.navigation(
                    leading: Icon(Icons.lock_outline, color: Colors.black),
                    trailing: Text(""),
                    title: Text('Privacy Policy'),
                    onPressed: (context) {},
                  ),
                  SettingsTile.navigation(
                    leading: Icon(Icons.security, color: Colors.black),
                    title: Text('Security Settings'),
                    trailing: Text(""),
                    onPressed: (context) {},
                  ),
                ],
              ),
              SettingsSection(
                title: Text('Child Settings'),
                tiles: <SettingsTile>[
                  SettingsTile(
                    title: Text('Select a child'),
                    trailing: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedOption.isNotEmpty
                              ? _selectedOption
                              : null,
                          hint: Text("Select a child"),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedOption = newValue!;
                            });
                          },
                          items: childrenNamesList
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          underline:
                              SizedBox.shrink(), // Remove the default underline
                        ),
                      ),
                    ),
                  ),
                  SettingsTile.switchTile(
                    leading: Icon(Icons.assistant, color: Colors.black),
                    title: Text('Can use sentence helper'),
                    initialValue: true,
                    onToggle: (bool value) {  },
                  ),
                  SettingsTile.switchTile(
                    leading: Icon(Icons.grid_on_rounded, color: Colors.black),
                    title: Text('Can use grid controls'),
                    initialValue: true,
                    onToggle: (bool value) {  },
                  ),
                  SettingsTile.switchTile(
                    leading: Icon(Icons.settings, color: Colors.black),
                    title: Text('Can use settings'),
                    initialValue: true,
                    onToggle: (bool value) {  },
                  ),
                  SettingsTile.navigation(
                    leading: Icon(Icons.color_lens, color: Colors.black),
                    title: Text('Child Theme'),
                    trailing: Text(""),
                    onPressed: (context) {},
                  ),
                ],
              ),
            ],
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

                    _showLoadingDialog(context);
                    try {
                      await _user.registerChild(
                          user!.uid,
                          _formKey.currentState?.instantValue['First name'],
                          _formKey.currentState?.instantValue['Last name'],
                          _formKey.currentState?.instantValue['Username'],
                          _formKey.currentState?.instantValue['Password']);

                      Navigator.pop(context);
                      Navigator.pop(context);
                      showTopSnackBar(
                        Overlay.of(context),
                        CustomSnackBar.success(
                          backgroundColor: Colors.green,
                          message: "Child has been added",
                        ),
                        displayDuration: Duration(seconds: 3),
                      );
                    } on UsernameAlreadyExistsException {
                      Navigator.pop(context);
                      showTopSnackBar(
                        Overlay.of(context),
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

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
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

final childSuccessSnackBar = SnackBar(
    content: Text('Child has been added'),
    behavior: SnackBarBehavior.floating,
    margin: EdgeInsets.only(top: 10, left: 10.0, right: 10.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(0),
    ),
    backgroundColor: Colors.green,
    duration: Duration(seconds: 3));
