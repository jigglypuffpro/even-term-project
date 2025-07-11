import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_parking_app/pages/LoginPage.dart';
import 'package:smart_parking_app/pages/verifyemail.dart';
import 'package:smart_parking_app/screens/map_screen.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
           builder: (context,snapshot){
            if(snapshot.hasData){
              print(snapshot.data);
              if( snapshot.data!.emailVerified){
                return MapScreen();
              }
              else {
                return Verify();
              }

            }
            else{
              return LoginPage();
            }
           }),
    );
  }
}
