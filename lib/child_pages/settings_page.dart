import 'package:firebase_auth/firebase_auth.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_app/auth_logic.dart';
import '../widgets/child_provider.dart';
import '../widgets/theme_provider.dart';

extension StringExtension on String {
  String capitalize() {
    return this.length > 0
        ? '${this[0].toUpperCase()}${this.substring(1)}'
        : '';
  }
}

class CustomSettings extends StatelessWidget {
  CustomSettings({super.key});

  Future<Map<String, String>> fetchChildProfile(
      String childId, BuildContext context) async {
    final firstname =
        Provider.of<ChildProvider>(context, listen: false).firstName;
    final lastname =
        Provider.of<ChildProvider>(context, listen: false).lastName;
    final username =
        Provider.of<ChildProvider>(context, listen: false).username;

    return {
      'firstName': firstname,
      'lastName': lastname,
      'username': username,
    };
  }

  @override
  Widget build(BuildContext context) {
    bool isLargeScreen = MediaQuery.of(context).size.width > 600;
    double titleFontSize = isLargeScreen ? 24.0 : 18.0;
    double tileFontSize = isLargeScreen ? 18.0 : 16.0;
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final childId = Provider.of<ChildProvider>(context).childId;

    return Scaffold(
      body: SettingsList(
        sections: [
          SettingsSection(
            title: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                'Common',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                leading: Icon(Icons.color_lens, color: theme.iconTheme.color),
                title: Text(
                  'Change Theme/Color',
                  style: TextStyle(fontSize: tileFontSize),
                ),
                value: Text(
                  themeProvider.themeName, // Display selected theme
                  style:
                      TextStyle(fontSize: tileFontSize, color: theme.hintColor),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(themeProvider.themeName.capitalize()),
                    Icon(Icons.chevron_right, color: theme.iconTheme.color),
                  ],
                ),
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
                                if (value != null) {
                                  if (childId != null) {
                                    await themeProvider
                                        .setTheme(value); // Placeholder method
                                  }
                                }
                                Navigator.of(context).pop(); // Close dialog
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
                title: Text(
                  'Log Out',
                  style: TextStyle(fontSize: tileFontSize, color: Colors.red),
                ),
                trailing: Icon(Icons.chevron_right, color: Colors.red),
                onPressed: (context) async {
                  logOutUser(context);
                  Navigator.of(context).pushReplacementNamed('/child_login');
                },
              ),
            ],
          ),
          SettingsSection(
            title: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                'Account',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                  leading: Icon(Icons.person, color: theme.iconTheme.color),
                  title: Text(
                    'Profile',
                    style: TextStyle(fontSize: tileFontSize),
                  ),
                  trailing:
                      Icon(Icons.chevron_right, color: theme.iconTheme.color),
                  onPressed: (context) async {
                    if (childId != null) {
                      // Fetch the profile data using the childId
                      Map<String, String> profile =
                          await fetchChildProfile(childId, context);

                      // Show the profile information in a dialog with the professional look
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return ProfileDialog(profile: profile);
                        },
                      );
                    }
                  }),
            ],
          ),
          SettingsSection(
            title: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                'Privacy',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                leading: Icon(Icons.lock_outline, color: theme.iconTheme.color),
                title: Text(
                  'Privacy Policy',
                  style: TextStyle(fontSize: tileFontSize),
                ),
                trailing:
                    Icon(Icons.chevron_right, color: theme.iconTheme.color),
                onPressed: (context) {
                  // Navigate to privacy policy
                },
              ),
            ],
          ),
        ],
        contentPadding: EdgeInsets.all(16.0), // Additional padding for clarity
      ),
    );
  }
}

class ProfileDialog extends StatelessWidget {
  final Map<String, String> profile;

  ProfileDialog({required this.profile});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Profile Information',
      ),
      content: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildProfileRow('First Name:', profile['firstName']!),
              buildProfileRow('Last Name:', profile['lastName']!),
              buildProfileRow('Username:', profile['username']!),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            'Close',
          ),
        ),
      ],
    );
  }

  Widget buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Text(
            '$label ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18, // Increased font size for the label
              color: Colors.blueGrey[800], // Added color for contrast
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20, // Increased font size for the value
                color:
                    Colors.blueGrey[700], // Slightly darker color for the value
              ),
            ),
          ),
        ],
      ),
    );
  }
}
