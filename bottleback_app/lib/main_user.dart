import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ต้อง Import หน้าจอทั้งหมดที่ถูกใช้ใน AuthGate
import 'package:bottleback_app/features_user/role_select.dart';
import 'package:bottleback_app/features_user/seller/dashboard.dart'; 
import 'package:bottleback_app/features_user/buyer/buyer_dashboard.dart'; // **สำคัญ: เพิ่มส่วนนี้**
import 'firebase_options.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
        scaffoldBackgroundColor: const Color(0xFFB2F5E6),
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00BFA6),
          primary: const Color(0xFF00BFA6),
          secondary: const Color(0xFFB4F8C8),
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

// --------------------------------------------------------------------------
// AuthGate: Widget ตรวจสอบสถานะการล็อกอิน
// --------------------------------------------------------------------------
class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // ถ้ามีข้อมูล User (ล็อกอินอยู่) ให้ไปหน้า Dashboard ของ Seller
        if (snapshot.hasData) {
          // เนื่องจาก Seller คือบทบาทที่ต้องล็อกอิน
          return const SellerDashboard(); 
        }
        
        // ถ้าไม่มีข้อมูล User (ไม่ได้ล็อกอิน) ให้ไปหน้าเลือกบทบาท
        return const RoleSelectScreen();
      },
    );
  }
}