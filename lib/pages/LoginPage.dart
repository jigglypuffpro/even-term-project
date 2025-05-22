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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome back ❤️",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6A1B9A),
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "LOGIN",
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 30),

                MyTextField(
                  icons: Icons.email,
                  lable: "Email id",
                  Onchange: _emailController,
                ),
                SizedBox(height: 16),
                MyTextField(
                  icons: Icons.lock_outline,
                  lable: "Password",
                  Onchange: _passwordController,
                ),
                SizedBox(height: 35),

                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : Column(
                  children: [
                    MyButton(
                      icon: Icons.login,
                      Btname: "LOGIN",
                      ontap: _signInWithEmailAndPassword,
                    ),
                    SizedBox(height: 25),
                    _buildDivider(),
                    SizedBox(height: 25),
                    _buildGoogleSignInButton(),
                  ],
                ),

                SizedBox(height: 35),
                Center(
                  child: Text(
                    "Not a member? 👤",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6A1B9A),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // ✨ Improved "Register Now" Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Color(0xFF6A1B9A), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Get.to(Signup()),
                    icon: Icon(Icons.app_registration, color: Color(0xFF6A1B9A)),
                    label: Text(
                      "Register Now",
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6A1B9A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // ✨ Improved "Forgot Password" Button
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => Get.to(Forgot()),
                    icon: Icon(Icons.lock_reset, color: Colors.deepPurple),
                    label: Text(
                      "Forgot Password?",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
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