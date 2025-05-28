import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:smart_parking_app/components/wrapper.dart';

class Verify extends StatefulWidget {
  @override
  _VerifyState createState() => _VerifyState();
}

class _VerifyState extends State<Verify> {
  @override
  void initState() {
    super.initState();
    sendVerifyLink();
  }

  Future<void> sendVerifyLink() async {
    final user = FirebaseAuth.instance.currentUser!;
    await user.sendEmailVerification().then((value) {
      Get.snackbar(
        'Verification Email Sent',
        'Please check your inbox to verify your account.',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.black,
        margin: EdgeInsets.all(16),
        snackPosition: SnackPosition.BOTTOM,
      );
    });
  }

  Future<void> reload() async {
    await FirebaseAuth.instance.currentUser!.reload();
    Get.offAll(() => Wrapper());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      appBar: AppBar(
        backgroundColor: Color(0xFF6A1B9A),
        title: Text("Email Verification"),
        centerTitle: true,
      ),
      body: Center(
        child: Card(
          margin: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mark_email_unread_rounded, size: 60, color: Color(0xFF6A1B9A)),
                SizedBox(height: 20),
                Text(
                  "Verify Your Email",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6A1B9A),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "A verification link has been sent to your email address. Please open your email and click the link.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                ),
                SizedBox(height: 25),
                ElevatedButton.icon(
                  onPressed: reload,
                  icon: Icon(Icons.refresh, color: Colors.white),
                  label: Text(
                    "Reload",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6A1B9A),
                    minimumSize: Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}