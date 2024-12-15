import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';
import '../auth_logic.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:test_app/authExceptions.dart';

import '../child_pages/home_page.dart';
import '../widgets/child_provider.dart';

class ParentSettingsPage extends StatefulWidget {
  ParentSettingsPage({super.key});

  @override
  State<ParentSettingsPage> createState() => _ParentSettingsPageState();
}

class _ParentSettingsPageState extends State<ParentSettingsPage> {
  String _selectedOption = 'Select Child';
  Map<String, Map> childrenSettingsData = {};
  bool isLoading = true;
  bool enableNotifications = true;
  bool useSentenceHelper = true;
  bool canUseGridControls = true;
  bool canUseEmotionHandling = true;
  bool canUseAudioPage = true;


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
              Map<String, dynamic>? childData = childSnapshot.data() as Map<String, dynamic>?;
              if (childData != null && childData['first name'] != null && childData['last name'] != null) {
                String childName = childData['first name'] + ", " + childData['last name'];
                childrenSettingsData[childName] = {'settings': childData['settings'], 'ID': childId};
                print(childrenSettingsData);
              } else {
                print("no data");
              }
            } else {
              print("dont work");
            }
          }

          setState(() {
            isLoading = false;
            if (childrenSettingsData.isNotEmpty) {
              _selectedOption = childrenSettingsData.keys.toList()[0];
              canUseGridControls = childrenSettingsData[_selectedOption]?['settings']['grid editing'];
              canUseEmotionHandling = childrenSettingsData[_selectedOption]?['settings']['emotion handling'];
              useSentenceHelper = childrenSettingsData[_selectedOption]?['settings']['sentence helper'];
              canUseAudioPage = childrenSettingsData[_selectedOption]?['settings']['audio page'];
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
    return Scaffold(
        appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.settings, color: Colors.black, size: 30),
                Row(children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3.0),
                    child: Image.asset("assets/imgs/logo_without_text.png",
                        width: 60),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: GradientText("MindBridge",
                        gradient: LinearGradient(colors: [
                          Colors.blue,
                          Colors.blueAccent,
                          Colors.deepPurpleAccent
                        ]),
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 30)),
                  )
                ]),
              ],
            )),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : SettingsList(
          sections: [
            SettingsSection(
              title: Text('Common'),
              tiles: <SettingsTile>[
                SettingsTile.navigation(
                  leading: Icon(Icons.language, color: Colors.black),
                  trailing: Text("English",
                      style: TextStyle(color: Colors.black87)),
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
                    final childProvider = Provider.of<ChildProvider>(
                        context,
                        listen: false);
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
                  title: Text('Enable Notifications'),
                  initialValue: enableNotifications,
                  onToggle: (value) {
                    setState(() {
                      enableNotifications = value;
                    });
                  },
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
                        items: childrenSettingsData.keys.toList()
                            .map<DropdownMenuItem<String>>(
                                (String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                        underline: SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
                SettingsTile.switchTile(
                  leading: Icon(Icons.assistant, color: Colors.black),
                  title: Text('Can use sentence helper'),
                  initialValue: useSentenceHelper,
                  onToggle: (value) async {
                    String currentChildId = childrenSettingsData[_selectedOption]?['ID'];
                    DocumentReference docRef = FirebaseFirestore.instance.collection('children').doc(currentChildId);
                    await docRef.update({
                      FieldPath(['settings', 'sentence helper']): value
                    });
                    setState(() {
                      useSentenceHelper = value;
                    });
                  },
                ),
                SettingsTile.switchTile(
                  leading:
                  Icon(Icons.grid_on_rounded, color: Colors.black),
                  title: Text('Can use grid controls'),
                  initialValue: canUseGridControls,
                  onToggle: (bool value) async {
                    String currentChildId = childrenSettingsData[_selectedOption]?['ID'];
                    DocumentReference docRef = FirebaseFirestore.instance.collection('children').doc(currentChildId);
                    await docRef.update({
                      FieldPath(['settings', 'grid editing']): value
                    });
                    setState((){
                      print(value);
                      canUseGridControls = value;
                    });
                  },
                ),
                SettingsTile.switchTile(
                  leading: Icon(Icons.settings, color: Colors.black),
                  title: Text('Emotion handling page'),
                  initialValue: canUseEmotionHandling,
                  onToggle: (bool value) async {
                    String currentChildId = childrenSettingsData[_selectedOption]?['ID'];
                    DocumentReference docRef = FirebaseFirestore.instance.collection('children').doc(currentChildId);
                    await docRef.update({
                      FieldPath(['settings', 'emotion handling']): value
                    });
                    setState((){
                      print(value);
                      canUseEmotionHandling = value;
                    });
                  },
                ),
                SettingsTile.switchTile(
                  leading:
                  Icon(Icons.grid_on_rounded, color: Colors.black),
                  title: Text('Music & stories page'),
                  initialValue: canUseGridControls,
                  onToggle: (bool value) async {
                    String currentChildId = childrenSettingsData[_selectedOption]?['ID'];
                    DocumentReference docRef = FirebaseFirestore.instance.collection('children').doc(currentChildId);
                    await docRef.update({
                      FieldPath(['settings', 'audio page']): value
                    });
                    setState((){
                      print(value);
                      canUseAudioPage = value;
                    });
                  },
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
        ));
  }
}

class RegisterChildForm extends StatefulWidget {
  const RegisterChildForm({super.key});

  @override
  State<RegisterChildForm> createState() => _RegisterChildFormState();
}

class _RegisterChildFormState extends State<RegisterChildForm> {
  final UserService _user = UserService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Username is required';
                } else if (value.length < 3) {
                  return 'Username must be at least 3 characters long';
                }
                return null;
              },
            ),
          ),
          // First Name Field
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextFormField(
              controller: _firstNameController,
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
          // Password Field
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                } else if (value.length < 6) {
                  return 'Password must be at least 6 characters long';
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
                          User? user = FirebaseAuth.instance.currentUser;
                          await _user.registerChild(
                            user!.uid,
                            _firstNameController.text.trim(),
                            _lastNameController.text.trim(),
                            _usernameController.text.trim(),
                            _passwordController.text.trim(),
                          );

                          // Success Handling
                          Navigator.pop(context); // Close loading dialog
                          Navigator.pop(context); // Close form dialog
                          showTopSnackBar(
                            Overlay.of(context),
                            CustomSnackBar.success(
                              backgroundColor: Colors.green,
                              message: "Child has been added",
                            ),
                            displayDuration: const Duration(seconds: 3),
                          );
                        } on UsernameAlreadyExistsException {
                          // Error Handling
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
                    child: const Text("Register Child"),
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