import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Forgot extends StatefulWidget {
  const Forgot({super.key});

  @override
  State<Forgot> createState() => _ForgotState();
}

class _ForgotState extends State<Forgot> {
  final TextEditingController _emailController = TextEditingController();
  reset()async{

    await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text);

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Forgot Password")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(hintText: 'Enter email'),
            ), // TextField
            // TextField
            ElevatedButton(
              onPressed: () => reset(),
              child: Text("Send Link"),
            ),
          ],
        ), // Column
      ), // Padding
    );
  }
}
