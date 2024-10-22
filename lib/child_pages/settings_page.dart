import 'package:firebase_auth/firebase_auth.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/child_provider.dart';

class CustomSettings extends StatelessWidget {
  CustomSettings({super.key});
  
  @override
  Widget build(BuildContext context) {
    return SettingsList(
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
            SettingsTile.navigation(
              onPressed: (value) {},
              leading: Icon(Icons.color_lens, color: Colors.black),
              trailing: Text(""),
              title: Text('Change Theme/Color'),
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

      ],
    );
  }
}
