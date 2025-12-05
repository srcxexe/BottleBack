import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // สำหรับตรวจสอบ Platform
import 'firebase_options.dart'; // ตรวจสอบว่ามีไฟล์นี้จากการรัน flutterfire configure

// Import หน้าจอของคุณ
import 'features_kiosk/kiosk_landing_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // 1. Initialize Firebase โดยใช้ Option ที่ถูกต้อง
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 2. *** FIX WINDOWS CRASH ***
    // ปิด Persistence บน Windows เพื่อป้องกันปัญหา Threading Violation
    // (Firebase บน Windows มีปัญหากับ Cache Database ในบางเวอร์ชัน)
    if (defaultTargetPlatform == TargetPlatform.windows) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false, 
      );
    }

  } catch (e) {
    print("Firebase Init Error: $e");
    // หากไม่มี firebase_options.dart หรือยังไม่ได้ configure ให้รันแบบ basic (แต่อาจจะไม่เสถียรบน Windows)
    try {
       await Firebase.initializeApp();
    } catch (e2) {
       print("Fallback Init Error: $e2");
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kiosk App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: const KioskLandingScreen(), // เริ่มต้นที่หน้า Landing
    );
  }
} 