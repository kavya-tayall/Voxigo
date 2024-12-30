import 'dart:typed_data';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:test_app/cache_utility.dart';
import '../auth_logic.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_app/security.dart';
import '../parent_pages/parent_reset_password.dart';
import '../parent_pages/parent_profile.dart';
import '../parent_pages/child_profile_edit.dart';
import '../parent_pages/child_delete_account.dart';
import '../parent_pages/child_add_newchild.dart';
import '../parent_pages/child_change_password.dart';
import '../child_pages/home_page.dart';
import '../widgets/child_provider.dart';
import '../widgets/parent_provider.dart';
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
    super.initState();
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
    // Re-fetch data if needed
    fetchChildrenData();
  }

  Future<void> _showAddChildDialog(BuildContext context) async {
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

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return const ResetPasswordDialog(); // Your custom dialog widget
      },
    );
  }

  Future<void> _showViewProfileDialog(
      BuildContext context, bool isEditMode) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        ParentProvider parentProvider =
            Provider.of<ParentProvider>(context, listen: false);
        ParentRecord parentRecord = parentProvider.parentData;
        return EditProfileDialog(
          userid: parentRecord.parentUid!,
          username: parentRecord.username!,
          firstName: parentRecord.firstname!,
          lastName: parentRecord.lastname!,
          email: parentRecord.email!,
          isEditMode: isEditMode, // View mode
        );
      },
    );
  }

  Future<void> _showChildProfileDialog(
      BuildContext context, bool isEditMode, String childId) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        ChildCollectionWithKeys childCollection =
            ChildCollectionWithKeys.instance;
        ChildRecord childRecord =
            childCollection.getRecord(childId) as ChildRecord;
        String parentId = FirebaseAuth.instance.currentUser?.uid ?? '';

        return EditChildProfileDialog(
          parentId: parentId,
          childId: childRecord.childuid,
          username: childRecord.username!,
          firstName: childRecord.firstName!,
          lastName: childRecord.lastName!,
          isEditMode: isEditMode,
        );
      },
    );
  }

  Future<void> _showChangeChildPasswordDialog(
      BuildContext context, String childId) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        // Assuming ChildCollectionWithKeys and ChildRecord are similar structures
        ChildCollectionWithKeys childCollection =
            ChildCollectionWithKeys.instance;
        ChildRecord childRecord =
            childCollection.getRecord(childId) as ChildRecord;
        String parentId = FirebaseAuth.instance.currentUser?.uid ?? '';

        return ChangeChildPasswordDialog(
          parentId: parentId,
          childId: childRecord.childuid,
          username: childRecord.username!,
          firstName: childRecord.firstName!,
          lastName: childRecord.lastName!,
        );
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
                        logOutUser(context);

                        Navigator.of(context)
                            .pushReplacementNamed('/parent_login');
                      },
                    ),
                  ],
                ),

                // Account Settings Section
                SettingsSection(
                  title: Text('Parent Account'),
                  tiles: <SettingsTile>[
                    SettingsTile.navigation(
                      leading: Icon(Icons.person, color: theme.iconTheme.color),
                      title: Text('Profile'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showViewProfileDialog(context, true),
                      ),
                      onPressed: (context) {
                        _showViewProfileDialog(context, false);
                      },
                    ),
                    SettingsTile.navigation(
                      leading: Icon(Icons.lock, color: theme.iconTheme.color),
                      trailing: Text(""),
                      title: Text('Change Password'),
                      onPressed: (context) async {
                        await _showChangePasswordDialog(context);
                      },
                    ),
                    SettingsTile.navigation(
                      leading: Icon(Icons.add, color: theme.iconTheme.color),
                      trailing: Text(""),
                      title: Text('Add Child'),
                      onPressed: (context) async {
                        await _showAddChildDialog(context);
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
                    SettingsTile.navigation(
                      leading:
                          Icon(Icons.child_care, color: theme.iconTheme.color),
                      title: Text('Manage Child Profile'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          if (_selectedOption.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please select a child first."),
                              ),
                            );
                            return; // Avoid unnecessary calls if no child is selected
                          }
                          await _showChildProfileDialog(
                              context, true, _selectedOption);
                          fetchChildrenData();
                        },
                      ),
                      onPressed: (context) async {
                        if (_selectedOption.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please select a child first."),
                            ),
                          );
                          return;
                        }
                        await _showChildProfileDialog(
                            context, false, _selectedOption!);
                        fetchChildrenData();
                      },
                    ),
                    SettingsTile.navigation(
                      leading:
                          Icon(Icons.password, color: theme.iconTheme.color),
                      title: Text('Change Child Password'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          if (_selectedOption.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please select a child first."),
                              ),
                            );
                            return; // Avoid unnecessary calls if no child is selected
                          }
                          await _showChangeChildPasswordDialog(
                              context, _selectedOption);
                          fetchChildrenData();
                        },
                      ),
                      onPressed: (context) async {
                        if (_selectedOption.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please select a child first."),
                            ),
                          );
                          return;
                        }
                        await _showChangeChildPasswordDialog(
                            context, _selectedOption!);
                        fetchChildrenData();
                      },
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

                // Privacy Section
                SettingsSection(
                  title: Text('Help and Support'),
                  tiles: <SettingsTile>[
                    SettingsTile.navigation(
                      leading:
                          Icon(Icons.privacy_tip, color: theme.iconTheme.color),
                      trailing: Text(""),
                      title: Text('Privacy Policy'),
                      onPressed: (context) {
                        Navigator.pushNamed(context, '/privacy_policy');
                      },
                    ),
                    SettingsTile.navigation(
                      leading: Icon(Icons.rule, color: theme.iconTheme.color),
                      trailing: Text(""),
                      title: Text('Term and Conditions'),
                      onPressed: (context) {},
                    ),
                    SettingsTile.navigation(
                      leading: Icon(Icons.contact_support,
                          color: theme.iconTheme.color),
                      trailing: Text(""),
                      title: Text('Contact Us'),
                      onPressed: (context) {},
                    ),
                  ],
                ),
                SettingsSection(
                  title: Text('Other'),
                  tiles: <SettingsTile>[
                    SettingsTile.navigation(
                      leading: Icon(Icons.delete_forever,
                          color: Color(0xFFff1744)), // Red 500
                      trailing: Text(""),
                      title: Text('Delete Parent Account'),
                      onPressed: (context) {},
                    ),
                  ],
                ),
              ],
            ),
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
