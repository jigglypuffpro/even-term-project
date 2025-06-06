import 'package:flutter/material.dart';

class SendFeedbackPage extends StatefulWidget {
  @override
  _SendFeedbackPageState createState() => _SendFeedbackPageState();
}

class _SendFeedbackPageState extends State<SendFeedbackPage> {
  final _controller = TextEditingController();

  void _submitFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Feedback submitted! Thank you.")),
    );
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final primaryColor = colorScheme.primary;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Send Feedback'),
        backgroundColor: primaryColor,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "We'd love to hear from you!",
              style: TextStyle(
                fontSize: 18,
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              maxLines: 6,
              cursorColor: primaryColor,
              decoration: InputDecoration(
                hintText: "Enter your feedback here...",
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: TextStyle(color: textColor),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: _submitFeedback,
              icon: const Icon(Icons.send),
              label: const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}