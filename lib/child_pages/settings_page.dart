import 'package:firebase_auth/firebase_auth.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/child_provider.dart';

class CustomSettings extends StatelessWidget {
  const CustomSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsList(
      sections: [
        SettingsSection(
          title: Text('Common'),
          tiles: <SettingsTile>[
            SettingsTile.navigation(
              leading: Icon(Icons.language),
              title: Text('Language'),
              value: Text('English'),
            ),
            SettingsTile.switchTile(
              onToggle: (value) {},
              initialValue: true,
              leading: Icon(Icons.format_paint),
              title: Text('Enable custom theme'),
            ),
            SettingsTile.navigation(
              leading: Icon(Icons.logout),
              title: Text('Log out'),
              onPressed: (context) async {
                // Get the ChildProvider instance
                final childProvider = Provider.of<ChildProvider>(context, listen: false);

                // Call logout method from the provider
                childProvider.logout();

                // Sign out from Firebase
                await FirebaseAuth.instance.signOut();

                // Navigate to the login page
                Navigator.of(context).pushReplacementNamed('/parent_login');
              },
            ),
          ],
        ),
        SettingsSection(
          title: Text('Account'),
          tiles: <SettingsTile>[
            SettingsTile.navigation(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onPressed: (context) {
                // Handle profile navigation
              },
            ),
            SettingsTile.navigation(
              leading: Icon(Icons.lock),
              title: Text('Change Password'),
              onPressed: (context) {
                // Handle change password navigation
              },
            ),
          ],
        ),
        SettingsSection(
          title: Text('Notifications'),
          tiles: <SettingsTile>[
            SettingsTile.switchTile(
              leading: Icon(Icons.notifications),
              title: Text('Enable Notifications'),
              onToggle: (value) {
                // Handle notifications toggle
              },
              initialValue: true,
            ),
          ],
        ),
        SettingsSection(
          title: Text('Privacy'),
          tiles: <SettingsTile>[
            SettingsTile.navigation(
              leading: Icon(Icons.lock_outline),
              title: Text('Privacy Policy'),
              onPressed: (context) {
                // Handle privacy policy navigation
              },
            ),
            SettingsTile.navigation(
              leading: Icon(Icons.security),
              title: Text('Security Settings'),
              onPressed: (context) {
                // Handle security settings navigation
              },
            ),
          ],
        ),
      ],
    );
  }
}
