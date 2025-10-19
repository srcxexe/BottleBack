import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bottleback_app/features_user/role_select.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const BottleBackUserApp());
}

class BottleBackUserApp extends StatelessWidget {
  const BottleBackUserApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BottleBack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF00BFA6),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00BFA6),
          primary: const Color(0xFF00BFA6),
          secondary: const Color(0xFFB4F8C8),
        ),
        useMaterial3: true,
      ),
      home: const RoleSelectScreen(),
    );
  }
}