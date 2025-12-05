import 'package:flutter/material.dart';
import 'kiosk_insert_screen.dart'; 
import '../../services/websocket_service.dart'; 
// import 'kiosk_login_screen.dart'; // ไม่ต้องใช้แล้ว
// import 'package:firebase_auth/firebase_auth.dart'; // ไม่ต้องใช้แล้ว

const Color kBackgroundColor = Color(0xFFF5F5F5); 
const Color kPrimaryColor = Color(0xFF00796B);    
const Color kBlackText = Colors.black87;           

class KioskLandingScreen extends StatefulWidget {
  const KioskLandingScreen({super.key});

  @override
  State<KioskLandingScreen> createState() => _KioskLandingScreenState();
}

class _KioskLandingScreenState extends State<KioskLandingScreen> {
  final WebSocketService _wsService = WebSocketService();

  @override
  void initState() {
    super.initState();
    // เชื่อมต่อ WebSocket รอไว้เมื่อเข้าหน้า Landing
    _wsService.connect();
  }

  void _handleStart(BuildContext context) {
    // 1. ส่งคำสั่ง "GO" ไปที่ Pi เพื่อเริ่มกระบวนการหยอดขวด
    _wsService.sendMessage("GO");

    // 2. ไปยังหน้า KioskInsertScreen ทันที โดยไม่ตรวจสอบสถานะ Login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const KioskInsertScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      // สามารถแตะที่ไหนก็ได้เพื่อเริ่ม
      body: InkWell(
        onTap: () => _handleStart(context), 
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo or Image
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryColor.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: const Icon(Icons.recycling_rounded, size: 100, color: kPrimaryColor),
              ),
              const SizedBox(height: 50),
              
              const Text(
                'Welcome to BottleBack Kiosk',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: kBlackText,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Press START or Touch Anywhere to begin',
                style: TextStyle(
                  fontSize: 20,
                  color: kBlackText.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 80),

              // START Button
              SizedBox(
                width: size.width * 0.5,
                height: 80,
                child: ElevatedButton.icon(
                  onPressed: () => _handleStart(context),
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 35),
                  label: const Text(
                    'START',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}