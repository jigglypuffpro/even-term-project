import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_parking_app/components/wrapper.dart';
import 'package:get/get.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  signup()async{

    await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _emailController.text, password:_passwordController.text);
    Get.offAll(Wrapper());
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(hintText: 'Enter email'),
            ), // TextField
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(hintText: 'Enter password'),
            ), // TextField
            ElevatedButton(
              onPressed: () => signup(),
              child: Text("Sign Up"),
            ),
          ],
        ), // Column
      ), // Padding
    );
  }
}
