import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class AccountPage extends StatelessWidget {
  final String name;
  final String email;

  AccountPage({required this.name, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Account')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(name),
            SizedBox(height: 16),
            Text('Email:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(email),
          ],
        ),
      ),
    );
  }
}