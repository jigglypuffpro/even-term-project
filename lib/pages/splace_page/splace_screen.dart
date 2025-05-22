import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '/pages/LoginPage.dart';
import '/screens/map_screen.dart'; // Adjust this to your actual Map screen

class Splace_Screen extends StatefulWidget {
  const Splace_Screen({super.key});

  @override
  State<Splace_Screen> createState() => _Splace_ScreenState();
}

class _Splace_ScreenState extends State<Splace_Screen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  void _navigate() async {
    await Future.delayed(const Duration(seconds: 3)); // Splash delay

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.emailVerified) {
      Get.offAll(() => MapScreen()); // Go to Home if logged in and verified
    } else {
      Get.offAll(() => const LoginPage()); // Go to Login if not signed in
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Expanded(
            flex: 9,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/animation/running_car.json',
                      width: 300,
                      height: 300,
                    ),
                  ],
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "CAR PARKING",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 10),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        // add changes
                        "This is a Car parking app for Smart car parking station, Here you can find Available slot and book your parking slot from any where with you phone",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),

        ]),
      ),
    );
  }
}
