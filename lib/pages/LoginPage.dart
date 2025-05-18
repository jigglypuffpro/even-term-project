import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/components/MyButton.dart';
import '/components/MyTextField.dart';
import '/pages/MapPage.dart';
import '/services/firebase_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  // Regular email/password sign in
  Future<void> _signInWithEmailAndPassword() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      Get.offAll(() => MapPage());
    } catch (e) {
      String message = 'An error occurred. Please try again.';

      if (e.toString().contains('user-not-found')) {
        message = 'No user found with this email.';
      } else if (e.toString().contains('wrong-password')) {
        message = 'Wrong password provided.';
      }

      _showErrorDialog(message);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Google sign in
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await FirebaseService.signInWithGoogle();

      if (userCredential != null) {
        // User successfully signed in with Google
        // screen // map screen
        Get.offAll(() => MapPage());
      } else {
        // User cancelled the Google sign-in flow
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showErrorDialog('Failed to sign in with Google. Please try again.');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade200,
        title: Text("L O G I N"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome back ❤️",
                  style: TextStyle(fontSize: 15),
                ),
                Text(
                  "LOGIN",
                  style: TextStyle(fontSize: 45, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 30),
                MyTextField(
                  icons: Icons.email,
                  lable: "Email id",
                  Onchange: _emailController,
                ),
                SizedBox(height: 10),
                MyTextField(
                  icons: Icons.password,
                  lable: "Password",
                  Onchange: _passwordController,
                ),
                SizedBox(height: 40),
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : Column(
                  children: [
                    MyButton(
                      icon: Icons.admin_panel_settings_rounded,
                      Btname: "LOGIN",
                      ontap: _signInWithEmailAndPassword,
                    ),
                    SizedBox(height: 20),
                    _buildDivider(),
                    SizedBox(height: 20),
                    _buildGoogleSignInButton(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text("OR", style: TextStyle(color: Colors.grey)),
        ),
        Expanded(child: Divider(thickness: 1)),
      ],
    );
  }

  Widget _buildGoogleSignInButton() {
    return InkWell(
      onTap: _signInWithGoogle,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/google_logo.png',
              height: 24,
              width: 24,
            ),
            SizedBox(width: 12),
            Text(
              "Sign in with Google",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}