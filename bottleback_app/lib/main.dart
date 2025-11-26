// import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ต้อง Import หน้าจอทั้งหมดที่ถูกใช้ใน AuthGate
import 'package:bottleback_app/features_user/role_select.dart';
import 'package:bottleback_app/features_kiosk/kiosk_landing_screen.dart';
import 'package:bottleback_app/features_user/seller/dashboard.dart'; 
import 'package:bottleback_app/features_user/buyer/buyer_dashboard.dart'; // **สำคัญ: เพิ่มส่วนนี้**
import 'firebase_options.dart'; 

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
  
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   runApp(const BottleBackUserApp());
// }

// class BottleBackUserApp extends StatelessWidget {
//   const BottleBackUserApp({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'BottleBack',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         primaryColor: const Color(0xFF00BFA6),
//         scaffoldBackgroundColor: const Color(0xFFB2F5E6),
//         fontFamily: 'Poppins',
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: const Color(0xFF00BFA6),
//           primary: const Color(0xFF00BFA6),
//           secondary: const Color(0xFFB4F8C8),
//         ),
//         useMaterial3: true,
//       ),
//       home: const AuthGate(),
//     );
//   }
// }

// // --------------------------------------------------------------------------
// // AuthGate: Widget ตรวจสอบสถานะการล็อกอิน
// // --------------------------------------------------------------------------
// class AuthGate extends StatelessWidget {
//   const AuthGate({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<User?>(
//       stream: FirebaseAuth.instance.authStateChanges(),
//       builder: (context, snapshot) {
        
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Scaffold(
//             body: Center(
//               child: CircularProgressIndicator(),
//             ),
//           );
//         }
//         return const KioskMainScreen();
//         // ถ้ามีข้อมูล User (ล็อกอินอยู่) ให้ไปหน้า Dashboard ของ Seller
//       //   if (snapshot.hasData) {
//       //     // เนื่องจาก Seller คือบทบาทที่ต้องล็อกอิน
//       //     return const SellerDashboard(); 
//       //   }
        
//       //   // ถ้าไม่มีข้อมูล User (ไม่ได้ล็อกอิน) ให้ไปหน้าเลือกบทบาท
//       //   return const RoleSelectScreen();
//       },
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// ต้องสร้างไฟล์นี้จากการตั้งค่า Firebase CLI (flutterfire configure)
import 'firebase_options.dart'; 
import '../features_kiosk/kiosk_main_screen.dart';

void main() async {
  // ต้องเรียกใช้ก่อนเสมอ หากมีการเรียกใช้ฟังก์ชัน native
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // 2. เรียกใช้ initializeApp() พร้อม Options ที่เหมาะสมกับ Platform
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully!');

  } catch (e) {
    // หากมีข้อผิดพลาด จะแสดงข้อความแจ้ง แต่แอปจะไม่รัน Firebase
    print('⚠️ Firebase initialization error: $e');
    print('Please check your firebase_options.dart and ensure "flutterfire configure" was run.');
  }

  runApp(const MyApp());
} 

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kiosk App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const KioskLandingScreen()
    );
  }
}