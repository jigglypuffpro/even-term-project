import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3E5F5),
      appBar: AppBar(
        title: Text("About Smart Park"),
        backgroundColor: Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
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
              ),
              _buildCard(
                title: "How It Works",
                content: """
1. Choose a parking area.
2. Select an available slot.
3. Set your parking duration.
4. Book and navigate to your spot.
""",
              ),
              _buildCard(
                title: "Technologies Used",
                content: """
• Flutter
• Firebase Realtime Database
• Google Maps API
• Dart
""",
              ),
              _buildCard(
                title: "Developer",
                content: "Developed by Shrey, Jagrati, Deepit as part of the Smart Mobility initiative.",
              ),
              _buildCard(
                title: "App Info",
                content: "Version: 1.0.0",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required String content}) {
    return Card(
      color: Colors.white,
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
                  color: Color(0xFF6A1B9A),
                )),
            SizedBox(height: 8),
            Text(content, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}