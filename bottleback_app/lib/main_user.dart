import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bottleback_app/features_user/role_select.dart';
import 'package:bottleback_app/features_user/seller/dashboard.dart'; // เพิ่ม import สำหรับ Dashboard
import 'firebase_options.dart'; // เพิ่ม import สำหรับ firebase_options

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // แก้ไขให้ใช้ DefaultFirebaseOptions เพื่อความถูกต้อง
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
      // --- ส่วนที่แก้ไข: เปลี่ยน home เป็น AuthGate ---
      home: const AuthGate(),
    );
  }
}

// --- Widget ใหม่ที่เพิ่มเข้ามา: ประตูตรวจสอบการล็อกอิน ---
class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ขณะกำลังรอการเชื่อมต่อ ให้แสดงหน้าโหลด
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // ถ้ามีข้อมูล user (ล็อกอินอยู่) ให้ไปหน้า Dashboard
        if (snapshot.hasData) {
          return const SellerDashboard();
        }

        // ถ้าไม่มีข้อมูล user (ยังไม่ได้ล็อกอิน) ให้ไปหน้าเลือก Role
        return const RoleSelectScreen();
      },
    );
  }
}

