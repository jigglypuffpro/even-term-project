import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_parking_app/screens/HelpFaqPage.dart';
import 'package:smart_parking_app/screens/SendFeedbackPage.dart';
import 'package:smart_parking_app/screens/account_page.dart';
import 'package:smart_parking_app/screens/booked_slots_page.dart';
import 'package:smart_parking_app/screens/theme_provider.dart';
import 'package:smart_parking_app/services/firebase_service.dart';

class SettingsPage extends StatefulWidget {
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notifEnabled = true;
  bool autoExtend = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Settings"),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle("Preferences", theme),
          SwitchListTile(
            activeColor: Color(0xFF6A1B9A),
            title: Text("Enable Notifications"),
            value: notifEnabled,
            onChanged: (val) => setState(() => notifEnabled = val),
          ),
          SwitchListTile(
            activeColor: Color(0xFF6A1B9A),
            title: Text("Dark Mode"),
            value: themeProvider.isDarkMode,
            onChanged: (val) {
              themeProvider.toggleTheme(val);
            },
          ),
          SwitchListTile(
            activeColor: Color(0xFF6A1B9A),
            title: Text("Auto Extend Parking"),
            subtitle: Text("Automatically extend booking if slot is still free."),
            value: autoExtend,
            onChanged: (val) => setState(() => autoExtend = val),
          ),
          SizedBox(height: 24),
          _buildSectionTitle("Account", theme),
          ListTile(
            leading: Icon(Icons.person, color: theme.iconTheme.color),
            title: Text("Profile Settings"),
            onTap: () async {
              final user = await FirebaseService.getCurrentUser();
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AccountPage(
                      name: user.displayName ?? 'No Name',
                      email: user.email ?? 'No Email',
                    ),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.history, color: theme.iconTheme.color),
            title: Text("Booking History"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BookedSlotsPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.lock, color: theme.iconTheme.color),
            title: Text("Change Password"),
            onTap: () {
              // Add navigation
            },
          ),
          SizedBox(height: 24),
          _buildSectionTitle("Support", theme),
          ListTile(
            leading: Icon(Icons.help_outline, color: theme.iconTheme.color),
            title: Text("Help & FAQs"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HelpFaqPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.feedback_outlined, color: theme.iconTheme.color),
            title: Text("Send Feedback"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SendFeedbackPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.redAccent),
            title: Text("Logout", style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              // Add logout logic
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: theme.textTheme.bodyLarge?.color,
        ),
      ),
    );
  }
}