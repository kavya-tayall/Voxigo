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
          // Privacy Section
          SettingsSection(
            title: Text('Help and Support'),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                leading: Icon(Icons.privacy_tip, color: theme.iconTheme.color),
                trailing: Text(""),
                title: Text('Privacy Policy'),
                onPressed: (context) {
                  // Show a dialog before navigating to Privacy Policy
                  showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                            title: Row(
                              children: [
                                Icon(Icons.lock_outline,
                                    color: Colors.blue, size: 24), // Visual cue
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'We Care About Your Privacy!',
                                    style: TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Hi there! Your parent or guardian has agreed to how we use your information to make the app work.",
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    color: Colors.black,
                                    height: 1.4, // Line spacing for readability
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "If you’re curious or have questions, you can ask them. We’re happy to help!",
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    color: Colors.black,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.pushNamed(
                                        context, '/privacy_policy');
                                  },
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline,
                                          color: Colors.blue),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Learn more about how we protect your data.",
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'Close',
                                  style: TextStyle(
                                      fontSize: 16.0, color: Colors.blue),
                                ),
                              ),
                            ],
                          ));
                },
              ),
              SettingsTile.navigation(
                leading: Icon(Icons.rule, color: theme.iconTheme.color),
                trailing: Text(""),
                title: Text('Terms of Use'),
                onPressed: (context) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Row(
                          children: [
                            Icon(Icons.assignment_outlined,
                                color: Colors.blue, size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Let’s Stay Safe Together!',
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Hi there! Before using the app, it’s important to understand some simple rules to keep everything safe and fun for everyone.",
                              style: TextStyle(
                                fontSize: 16.0,
                                color: Colors.black,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "You can read these rules with help from a parent or guardian. If you’re ready, let’s take a look together!",
                              style: TextStyle(
                                fontSize: 16.0,
                                color: Colors.black,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Not Now',
                              style:
                                  TextStyle(fontSize: 16.0, color: Colors.blue),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // Close the dialog
                              Navigator.pushNamed(
                                  context, '/terms_of_use'); // Navigate
                            },
                            child: Text(
                              'Read the Rules',
                              style:
                                  TextStyle(fontSize: 16.0, color: Colors.blue),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              SettingsTile.navigation(
                leading:
                    Icon(Icons.contact_support, color: theme.iconTheme.color),
                trailing: Text(""),
                title: Text('Contact Us'),
                onPressed: (context) {
                  Navigator.of(context).pushNamed('/contact_us');
                },
              ),
            ],
          )
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
    // Define a consistent color scheme

    final TextStyle titleStyle = TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
    );
    final TextStyle labelStyle = TextStyle(
      fontSize: 16.0,
      fontWeight: FontWeight.w600,
      color: Colors.blueGrey[800],
    );
    final TextStyle valueStyle = TextStyle(
      fontSize: 16.0,
      color: Colors.blueGrey[700],
    );

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      titlePadding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      contentPadding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 0.0),
      title: Row(
        children: [
          Icon(Icons.person_outline, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your Profile',
              style: titleStyle,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildProfileRow(
                  'First Name:', profile['firstName']!, labelStyle, valueStyle),
              buildProfileRow(
                  'Last Name:', profile['lastName']!, labelStyle, valueStyle),
              buildProfileRow(
                  'Username:', profile['username']!, labelStyle, valueStyle),
            ],
          ),
        ),
      ),
      actionsPadding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: Text(
            'Close',
            style: TextStyle(
              fontSize: 16.0,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildProfileRow(
      String label, String value, TextStyle labelStyle, TextStyle valueStyle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            width: 100, // Fixed width for labels to align text
            child: Text(
              label,
              style: labelStyle,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }
}
