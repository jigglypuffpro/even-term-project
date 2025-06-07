import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.colorScheme.surface;
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("About Smart Park"),
        backgroundColor: theme.appBarTheme.backgroundColor ?? primaryColor,
        foregroundColor: theme.appBarTheme.foregroundColor ?? Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCard(
                title: "What is Smart Park?",
                content:
                "Smart Park helps users find and book available parking slots in real-time. With live updates, Google Maps navigation, and flexible booking durations, parking is now easy and efficient.",
                primaryColor: primaryColor,
                cardColor: cardColor,
                textColor: textColor,
              ),
              _buildCard(
                title: "Key Features",
                content: """
• Real-time Slot Availability
• Google Maps Navigation
• Flexible Booking Durations
• Auto Expiry of Booked Slots
• Live Firebase Sync for Slot Status
""",
                primaryColor: primaryColor,
                cardColor: cardColor,
                textColor: textColor,
              ),
              _buildCard(
                title: "How It Works",
                content: """
1. Choose a parking area.
2. Select an available slot.
3. Set your parking duration.
4. Book and navigate to your spot.
""",
                primaryColor: primaryColor,
                cardColor: cardColor,
                textColor: textColor,
              ),
              _buildCard(
                title: "Technologies Used",
                content: """
• Flutter
• Firebase Realtime Database
• Google Maps API
• Dart
""",
                primaryColor: primaryColor,
                cardColor: cardColor,
                textColor: textColor,
              ),
              _buildCard(
                title: "Developer",
                content:
                "Developed by Shrey, Jagrati, Deepit as part of the Smart Mobility initiative.",
                primaryColor: primaryColor,
                cardColor: cardColor,
                textColor: textColor,
              ),
              _buildCard(
                title: "App Info",
                content: "Version: 1.0.0",
                primaryColor: primaryColor,
                cardColor: cardColor,
                textColor: textColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String content,
    required Color primaryColor,
    required Color cardColor,
    required Color textColor,
  }) {
    return Card(
      color: cardColor,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                )),
            const SizedBox(height: 8),
            Text(
              content,
              style: TextStyle(fontSize: 16, color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}