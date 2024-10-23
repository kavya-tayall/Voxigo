import 'package:firebase_auth/firebase_auth.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/child_provider.dart';

class CustomSettings extends StatelessWidget {
  CustomSettings({super.key});

  @override
  Widget build(BuildContext context) {

    bool isLargeScreen = MediaQuery.of(context).size.width > 600;
    double titleFontSize = isLargeScreen ? 24.0 : 16.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(fontSize: isLargeScreen ? 40 : 30, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: Text(
              'Common',
              style: TextStyle(fontSize: titleFontSize),
            ),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                leading: Icon(Icons.language, color: Colors.black),
                trailing: Text(""),
                title: Text('Language', style: TextStyle(fontSize: titleFontSize)),
                value: Text('English', style: TextStyle(fontSize: titleFontSize)),
              ),
              SettingsTile.navigation(
                onPressed: (value) {},
                leading: Icon(Icons.color_lens, color: Colors.black),
                trailing: Text(""),
                title: Text('Change Theme/Color', style: TextStyle(fontSize: titleFontSize)),
              ),
              SettingsTile.navigation(
                leading: Icon(Icons.logout, color: Colors.black),
                title: Text('Log out', style: TextStyle(fontSize: titleFontSize)),
                trailing: Text(""),
                onPressed: (context) async {
                  final childProvider = Provider.of<ChildProvider>(context, listen: false);
                  childProvider.logout();
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushReplacementNamed('/parent_login');
                },
              ),
            ],
          ),
          SettingsSection(
            title: Text(
              'Account',
              style: TextStyle(fontSize: titleFontSize),
            ),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                leading: Icon(Icons.person, color: Colors.black),
                title: Text('Profile', style: TextStyle(fontSize: titleFontSize)),
                trailing: Text(""),
                onPressed: (context) {},
              ),
              SettingsTile.navigation(
                leading: Icon(Icons.lock, color: Colors.black),
                trailing: Text(""),
                title: Text('Change Password', style: TextStyle(fontSize: titleFontSize)),
                onPressed: (context) {},
              ),
            ],
          ),
          SettingsSection(
            title: Text(
              'Notifications',
              style: TextStyle(fontSize: titleFontSize),
            ),
            tiles: <SettingsTile>[
              SettingsTile.switchTile(
                leading: Icon(Icons.notifications, color: Colors.black),
                trailing: Text(""),
                title: Text('Enable Notifications', style: TextStyle(fontSize: titleFontSize)),
                onToggle: (value) {},
                initialValue: true,
              ),
            ],
          ),
          SettingsSection(
            title: Text(
              'Privacy',
              style: TextStyle(fontSize: titleFontSize),
            ),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                leading: Icon(Icons.lock_outline, color: Colors.black),
                trailing: Text(""),
                title: Text('Privacy Policy', style: TextStyle(fontSize: titleFontSize)),
                onPressed: (context) {},
              ),
              SettingsTile.navigation(
                leading: Icon(Icons.security, color: Colors.black),
                title: Text('Security Settings', style: TextStyle(fontSize: titleFontSize)),
                trailing: Text(""),
                onPressed: (context) {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
