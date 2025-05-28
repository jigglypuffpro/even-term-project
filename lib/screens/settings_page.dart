import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notifEnabled = true;
  bool darkMode = false;
  bool autoExtend = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3E5F5),
      appBar: AppBar(
        title: Text("Settings"),
        backgroundColor: Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle("Preferences"),
          SwitchListTile(
            activeColor: Color(0xFF6A1B9A),
            title: Text("Enable Notifications"),
            value: notifEnabled,
            onChanged: (val) {
              setState(() => notifEnabled = val);
            },
          ),
          SwitchListTile(
            activeColor: Color(0xFF6A1B9A),
            title: Text("Dark Mode"),
            value: darkMode,
            onChanged: (val) {
              setState(() => darkMode = val);
            },
          ),
          SwitchListTile(
            activeColor: Color(0xFF6A1B9A),
            title: Text("Auto Extend Parking"),
            subtitle: Text("Automatically extend booking if slot is still free."),
            value: autoExtend,
            onChanged: (val) {
              setState(() => autoExtend = val);
            },
          ),
          SizedBox(height: 24),
          _buildSectionTitle("Account"),
          ListTile(
            leading: Icon(Icons.person, color: Color(0xFF6A1B9A)),
            title: Text("Profile Settings"),
            onTap: () {
              // Navigate to Profile Settings Page
            },
          ),
          ListTile(
            leading: Icon(Icons.history, color: Color(0xFF6A1B9A)),
            title: Text("Booking History"),
            onTap: () {
              // Navigate to Booking History
            },
          ),
          ListTile(
            leading: Icon(Icons.lock, color: Color(0xFF6A1B9A)),
            title: Text("Change Password"),
            onTap: () {
              // Navigate to Password Change
            },
          ),
          SizedBox(height: 24),
          _buildSectionTitle("Support"),
          ListTile(
            leading: Icon(Icons.help_outline, color: Color(0xFF6A1B9A)),
            title: Text("Help & FAQs"),
            onTap: () {
              // Navigate to Help Page
            },
          ),
          ListTile(
            leading: Icon(Icons.feedback_outlined, color: Color(0xFF6A1B9A)),
            title: Text("Send Feedback"),
            onTap: () {
              // Open feedback form or email
            },
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.redAccent),
            title: Text("Logout", style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              // Implement logout logic
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6A1B9A))),
    );
  }
}