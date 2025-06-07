import 'package:flutter/material.dart';

class HelpFaqPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Help & FAQs'),
        foregroundColor: colorScheme.onPrimary,
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _faqTile("How do I book a parking slot?", "Go to the map, tap on an available slot, and confirm.", primaryColor, textColor),
            _faqTile("How can I reset my password?", "Click on 'Forgot password?' on the login screen.", primaryColor, textColor),
            _faqTile("Can I cancel a booking?", "Currently, bookings are time-bound and cannot be canceled.", primaryColor, textColor),
            _faqTile("Is my data secure?", "Yes, we use Firebase Auth and encrypted connections.", primaryColor, textColor),
          ],
        ),
      ),
    );
  }

  Widget _faqTile(String question, String answer, Color primaryColor, Color textColor) {
    return ExpansionTile(
      title: Text(
        question,
        style: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            answer,
            style: TextStyle(color: textColor),
          ),
        ),
      ],
    );
  }
}