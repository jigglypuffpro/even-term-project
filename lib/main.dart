// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'screens/map_screen.dart';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//   runApp(MaterialApp(
//     home: MapScreen(),
//   ));
// }


import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_parking_app/screens/theme_provider.dart';
import 'controller/splace_controller.dart'; // Relative import from lib directory
import 'pages/splace_page/splace_screen.dart'; // Adjust if path is different
import 'config/routes.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
      ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
          child: MyApp(),
      ),
      );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    SplaceController splaceController = Get.put(SplaceController());
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Car Parking',
      getPages: pages,
      themeMode: themeProvider.themeMode,
      // Light theme
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF6A1B9A),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Color(0xFFF5EAFE),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF6A1B9A),
          foregroundColor: Colors.white,
        ),
        iconTheme: IconThemeData(color: Color(0xFF6A1B9A)),
        textTheme: ThemeData.light().textTheme.apply(bodyColor: Colors.black),
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF6A1B9A),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
        textTheme: ThemeData.dark().textTheme.apply(bodyColor: Colors.white),
      ),
      // theme: ThemeData(useMaterial3: true),
      home: const Splace_Screen(),
    );
  }
}