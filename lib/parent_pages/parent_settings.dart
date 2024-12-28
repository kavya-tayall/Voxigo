import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_app/cache_utility.dart';
import 'package:test_app/getauthtokenandkey.dart';
import '../auth_logic.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:test_app/authExceptions.dart';
import 'package:test_app/security.dart';

import '../child_pages/home_page.dart';
import '../widgets/child_provider.dart';
import '../widgets/theme_provider.dart';

extension StringExtension on String {
  String capitalize() {
    return this.length > 0
        ? '${this[0].toUpperCase()}${this.substring(1)}'
        : '';
  }
}

class ParentSettingsPage extends StatefulWidget {
  ParentSettingsPage({super.key});

  @override
  State<ParentSettingsPage> createState() => _ParentSettingsPageState();
}

class _ParentSettingsPageState extends State<ParentSettingsPage> {
  String _selectedOption = 'Select Child';
  String _selectedOptionId = '';
  List<Map<String, String>> childrenNamesList = [];
  Map<String, Map> childrenSettingsData = {};
  bool isLoading = true;
  bool enableNotifications = true;
  bool useSentenceHelper = true;
  bool canUseGridControls = true;
  bool canUseEmotionHandling = true;
  bool canUseAudioPage = true;
  late ThemeProvider themeProvider;

  @override
  void initState() {
    fetchChildrenData();
  }

  void resetToInitialState() {
    setState(() {
      _selectedOption = 'Select Child';
      _selectedOptionId = '';
      childrenNamesList = [];
      childrenSettingsData = {};
      isLoading = true;
      enableNotifications = true;
      useSentenceHelper = true;
      canUseGridControls = true;
      canUseEmotionHandling = true;
      canUseAudioPage = true;
    });
    print('resetToInitialState');
    // Re-fetch data if needed
    fetchChildrenData();
  }

  Future<void> _showFormDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return RegisterChildDialog(); // Your custom dialog widget
      },
    );
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return const DeleteChildDialog(); // Your custom dialog widget
      },
    );
  }

  Future<void> fetchChildrenData() async {
    try {
      String parentEmailasUserName = '';
      String parentId = '';

      User? currentUser = FirebaseAuth.instance.currentUser;
      print('Current user: $currentUser');
      if (currentUser != null) {
        parentId = currentUser.uid; // Removed re-declaration
        print('Parent ID: $parentId');
        DocumentSnapshot parentSnapshot = await FirebaseFirestore.instance
            .collection('parents')
            .doc(parentId)
            .get();

        if (parentSnapshot.exists) {
          Map<String, dynamic>? parentData =
              parentSnapshot.data() as Map<String, dynamic>?;
          parentEmailasUserName = parentData?['email'] ?? '';
          if (parentData != null && parentData['children'] != null) {
            List<String> childIds = List<String>.from(parentData['children']);
            print('Calling fetchAndStoreChildrenData for $childIds');
            await fetchAndStoreChildrenData(
                parentId, childIds, context, parentEmailasUserName, true);
          }
        }
      }

      // Wait for generateChildNameDropdownItems to complete
      print('Generating child name dropdown items');
      List<Map<String, String>> fetchedData =
          await UserListForParentService.generateChildNameDropdownItems();
      print('Fetched name data: $fetchedData');

      final childCollection = ChildCollectionWithKeys.instance;

      // Clear the map to avoid leftover data
      childrenSettingsData.clear();

      // Traverse through the records in the collection
      for (ChildRecord record in childCollection.allRecords) {
        childrenSettingsData[record.childuid] = {
          'name': "${record.firstName ?? ''} ${record.lastName ?? ''}".trim(),
          'settings': record.settings,
        };
      }

      print('Children settings data: $childrenSettingsData');

      // Update the UI state only after all processing completes
      setState(() {
        isLoading = false;
        childrenNamesList = fetchedData;

        if (childrenNamesList.isNotEmpty) {
          // Default to the first child's ID
          _selectedOption = childrenNamesList.first['childId'] ?? '';

          if (childrenSettingsData.isNotEmpty) {
            _selectedOptionId = childrenSettingsData.keys.first;
            final settings =
                childrenSettingsData[_selectedOptionId]?['settings'];

            if (settings is ChildSettings) {
              canUseGridControls = settings.gridEditing ?? false;
              canUseEmotionHandling = settings.emotionHandling ?? false;
              useSentenceHelper = settings.sentenceHelper ?? false;
              canUseAudioPage = settings.audioPage ?? false;
            } else {
              resetSettings();
            }
          } else {
            resetSettings();
          }
        } else {
          resetSettings();
        }
      });
    } catch (e) {
      print('Error fetching children data: $e');
    }
  }

  void resetSettings() {
    _selectedOption = '';
    canUseGridControls = false;
    canUseEmotionHandling = false;
    useSentenceHelper = false;
    canUseAudioPage = false;
  }

  void _fetchSwitchValueForUser(String childId) async {
    print('childId $childId');
    final childCollection = ChildCollectionWithKeys.instance;
    ChildRecord childRecord = childCollection.getRecord(childId) as ChildRecord;
    Uint8List childIchildsecureKey = childRecord.childsecureKey;
    Uint8List iv = childRecord.childbaserecordiv as Uint8List;

    ChildSettings settings =
        await getChildSettings(childId, childIchildsecureKey, iv);
    print('settings $settings.gridEditing');
    setState(() {
      canUseGridControls = settings.gridEditing ?? false;
      canUseEmotionHandling = settings.emotionHandling ?? false;
      useSentenceHelper = settings.sentenceHelper ?? false;
      canUseAudioPage = settings.audioPage ?? false;
    });
  }

  void handleChildSelection(String selectedId, dynamic data) {
    print('Selected Child ID: $selectedId');
    // Pass this ID to other methods or perform further actions
    encryptSetting(selectedId, data);
  }

  String encryptSetting(String childId, dynamic data) {
    // Perform logic with the selected child ID
    print('Processing logic for child ID: $childId');
    final childCollection = ChildCollectionWithKeys.instance;
    ChildRecord childRecord = childCollection.getRecord(childId) as ChildRecord;
    Uint8List secureKey = childRecord.childsecureKey;
    Uint8List iv = childRecord.childbaserecordiv!;
    Uint8List textBytes = Uint8List.fromList(utf8.encode(data.toString()));

    Uint8List encryptedData = aesGcmEncrypt(textBytes, secureKey, iv);
    return base64Encode(encryptedData);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.settings, color: Colors.black, size: 30),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3.0),
                  child: Image.asset("assets/imgs/logo_without_text.png",
                      width: 60),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: GradientText(
                    "Voxigo",
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue,
                        Colors.blueAccent,
                        Colors.deepPurpleAccent,
                      ],
                    ),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SettingsList(
              sections: [
                // Common Settings Section
                SettingsSection(
                  title: Text('Common'),
                  tiles: <SettingsTile>[
                    SettingsTile.navigation(
                      leading:
                          Icon(Icons.palette, color: theme.iconTheme.color),
                      title: Text('Choose Theme'),
                      trailing: Text(themeProvider.themeName.capitalize()),
                      onPressed: (context) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("Select Theme"),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: ThemeProvider.themes.map((theme) {
                                  return RadioListTile(
                                    value: theme.id,
                                    groupValue: themeProvider.themeName,
                                    title: Text(theme.name),
                                    onChanged: (value) async {
                                      await themeProvider.setTheme(
                                        value!,
                                      );
                                      Navigator.of(context)
                                          .pop(); // Close dialog
                                    },
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    SettingsTile.navigation(
                      leading: Icon(Icons.logout, color: theme.iconTheme.color),
                      title: Text('Log out'),
                      trailing: Text(""),
                      onPressed: (context) async {
                        final childProvider = Provider.of<ChildProvider>(
                          context,
                          listen: false,
                        );
                        ApiService.instance.dispose();
                        UserSession.instance.dispose();
                        ChildCollectionWithKeys.instance.dispose();
                        print('All singleton classes disposed during logout');
                        childProvider.logout();
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        await FirebaseAuth.instance.signOut();
                        themeProvider.setdefaultTheme();
                        Navigator.of(context)
                            .pushReplacementNamed('/parent_login');
                      },
                    ),
                  ],
                ),

                // Account Settings Section
                SettingsSection(
                  title: Text('Account'),
                  tiles: <SettingsTile>[
                    SettingsTile.navigation(
                      leading: Icon(Icons.person, color: theme.iconTheme.color),
                      title: Text('Profile'),
                      trailing: Text(""),
                      onPressed: (context) {},
                    ),
                    SettingsTile.navigation(
                      leading: Icon(Icons.lock, color: theme.iconTheme.color),
                      trailing: Text(""),
                      title: Text('Change Password'),
                      onPressed: (context) {},
                    ),
                    SettingsTile.navigation(
                      leading: Icon(Icons.add, color: theme.iconTheme.color),
                      trailing: Text(""),
                      title: Text('Add Child'),
                      onPressed: (context) async {
                        await _showFormDialog(context);
                        fetchChildrenData();
                      },
                    ),
                    SettingsTile.navigation(
                      leading: Icon(Icons.delete, color: theme.iconTheme.color),
                      trailing: Text(""),
                      title: Text('Delete Child'),
                      onPressed: (context) async {
                        await _showDeleteDialog(context);
                        fetchChildrenData();
                      },
                    ),
                  ],
                ),

                // Privacy Section
                SettingsSection(
                  title: Text('Privacy'),
                  tiles: <SettingsTile>[
                    SettingsTile.navigation(
                      leading: Icon(Icons.lock_outline,
                          color: theme.iconTheme.color),
                      trailing: Text(""),
                      title: Text('Privacy Policy'),
                      onPressed: (context) {},
                    ),
                  ],
                ),

                // Child Settings Section
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
                            value: _selectedOption,
                            items: childrenNamesList.map((child) {
                              return DropdownMenuItem<String>(
                                value: child['childId'],
                                child: Text(child['childName']!),
                              );
                            }).toList(),
                            hint: Text(childrenNamesList.isEmpty
                                ? "No children available"
                                : "Select a child"),
                            onChanged: childrenNamesList.isNotEmpty
                                ? (newValue) {
                                    setState(() {
                                      _selectedOption = newValue!;
                                      print("new value $newValue");
                                    });
                                    _fetchSwitchValueForUser(newValue!);
                                  }
                                : null,
                            underline: SizedBox.shrink(),
                            disabledHint: Text("No children available"),
                          ),
                        ),
                      ),
                    ),
                    SettingsTile.switchTile(
                      leading:
                          Icon(Icons.assistant, color: theme.iconTheme.color),
                      title: Text('Can use sentence helper'),
                      initialValue: useSentenceHelper,
                      onToggle: (value) async {
                        DocumentReference docRef = FirebaseFirestore.instance
                            .collection('children')
                            .doc(_selectedOption);
                        await docRef.update({
                          FieldPath(['settings', 'sentence helper']):
                              encryptSetting(_selectedOption, value),
                        });
                        setState(() {
                          useSentenceHelper = value;
                        });
                      },
                    ),
                    SettingsTile.switchTile(
                      leading: Icon(Icons.grid_on_rounded,
                          color: theme.iconTheme.color),
                      title: Text('Can use grid controls'),
                      initialValue: canUseGridControls,
                      onToggle: (bool value) async {
                        DocumentReference docRef = FirebaseFirestore.instance
                            .collection('children')
                            .doc(_selectedOption);
                        await docRef.update({
                          FieldPath(['settings', 'grid editing']):
                              encryptSetting(_selectedOption, value),
                        });
                        setState(() {
                          canUseGridControls = value;
                        });
                      },
                    ),
                    SettingsTile.switchTile(
                      leading:
                          Icon(Icons.settings, color: theme.iconTheme.color),
                      title: Text('Emotion handling page'),
                      initialValue: canUseEmotionHandling,
                      onToggle: (bool value) async {
                        DocumentReference docRef = FirebaseFirestore.instance
                            .collection('children')
                            .doc(_selectedOption);
                        await docRef.update({
                          FieldPath(['settings', 'emotion handling']):
                              encryptSetting(_selectedOption, value),
                        });
                        setState(() {
                          canUseEmotionHandling = value;
                        });
                      },
                    ),
                    SettingsTile.switchTile(
                      leading: Icon(Icons.grid_on_rounded,
                          color: theme.iconTheme.color),
                      title: Text('Music & stories page'),
                      initialValue: canUseAudioPage,
                      onToggle: (bool value) async {
                        DocumentReference docRef = FirebaseFirestore.instance
                            .collection('children')
                            .doc(_selectedOption);
                        await docRef.update({
                          FieldPath(['settings', 'audio page']):
                              encryptSetting(_selectedOption, value),
                        });
                        setState(() {
                          canUseAudioPage = value;
                        });
                      },
                    ),
                    SettingsTile.navigation(
                      leading:
                          Icon(Icons.color_lens, color: theme.iconTheme.color),
                      title: Text('Child Theme'),
                      trailing: Text(""),
                      onPressed: (context) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("Select Theme"),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: ThemeProvider.themes.map((theme) {
                                  return RadioListTile(
                                    value: theme.id,
                                    groupValue: themeProvider.themeName,
                                    title: Text(theme.name),
                                    onChanged: (value) async {
                                      await themeProvider.setChildTheme(
                                        value!,
                                        _selectedOption,
                                      );
                                      Navigator.of(context)
                                          .pop(); // Close dialog
                                    },
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
    );
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
                          String newChildId =
                              await _user.encryptChildDataAndRegister(
                            user!.uid,
                            _firstNameController.text.trim(),
                            _lastNameController.text.trim(),
                            _usernameController.text.trim(),
                            _passwordController.text.trim(),
                          );
                          print('New child ID: $newChildId');
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

final childSuccessSnackBar = SnackBar(
    content: Text('Child has been added'),
    behavior: SnackBarBehavior.floating,
    margin: EdgeInsets.only(top: 10, left: 10.0, right: 10.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(0),
    ),
    backgroundColor: Colors.green,
    duration: Duration(seconds: 3));
