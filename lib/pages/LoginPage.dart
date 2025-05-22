import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smart_parking_app/pages/splace_page/forgot.dart';
import 'package:smart_parking_app/pages/splace_page/signup.dart';
import 'package:smart_parking_app/screens/map_screen.dart';
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
    void _showSnackBar(String message) {
      Get.snackbar(
        "Login Failed",
        message,
        backgroundColor: Colors.red.shade100,
        snackPosition: SnackPosition.BOTTOM,
        margin: EdgeInsets.all(10),
        colorText: Colors.black,
        duration: Duration(seconds: 3),
      );
    }
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      _showSnackBar("Please fill in all fields.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      Get.offAll(() => MapScreen());
    } on FirebaseAuthException catch (e) {
      String message ="Invalid credentials ,Please try again. " ; //= "An error occurred. Please try again.";
        if (e.code == 'user-not-found' || e.code == 'wrong-password') {
          message = "Invalid credentials";

      }

      _showSnackBar(message);
    }
    catch (e) {
      _showSnackBar("Something went wrong. Please try again.");
    }
    finally {
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
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        _showErrorDialog('Google Sign-In was cancelled.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Attempt Firebase sign-in
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      // If signed in successfully, navigate
      if (userCredential.user != null) {
        Get.offAll(() => MapScreen());
      } else {
        _showErrorDialog("Google Sign-In failed. Please try again.");
      }

    } on FirebaseAuthException catch (e) {
      String errorMessage = "Authentication failed.";

      if (e.code == 'account-exists-with-different-credential') {
        errorMessage = "Account exists with a different sign-in method.";
      } else if (e.code == 'invalid-credential') {
        errorMessage = "Invalid credentials provided.";
      }

      _showErrorDialog(errorMessage);
    }catch (e) {
      print("Google Sign-In error: $e");

      if (e.toString().contains("ApiException: 10")) {
        _showErrorDialog("Google Sign-In failed due to misconfiguration. Please check SHA-1 in Firebase.");
      } else {
        _showErrorDialog("An unexpected error occurred: ${e.toString()}");
      }

      setState(() {
        _isLoading = false;
      });
    }finally {
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6A1B9A), // Deep purple matching your theme
                    letterSpacing: 0.5,
                  ),
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
                Padding(
                  padding: const EdgeInsets.only(left: 20.0, top: 20.0),
                  child: Text(
                    "Not a member? 👤",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6A1B9A), // A deep purple shade matching your theme
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(height:30,),
                ElevatedButton(
                  onPressed: () => Get.to(Signup()),
                  child: Text("Register Now"),
                ),
                SizedBox(height:30,),
                ElevatedButton(
                  onPressed: () => Get.to(Forgot()),
                  child: Text("Forgot password?"),
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
          child: Text("OR Continue with", style: TextStyle(color: Colors.grey)),
        ),
        Expanded(child: Divider(thickness: 1)),
      ],
    );
  }

  Widget _buildGoogleSignInButton() {
    return InkWell(
      onTap: _signInWithGoogle ,
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