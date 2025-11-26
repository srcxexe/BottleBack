import 'package:flutter/material.dart';
// ต้อง import หน้าจอหลักเพื่อนำทางไปหลังจากกดเริ่มต้น
import 'kiosk_main_screen.dart'; 

// --- Light Theme Constants (คัดลอกมาจากไฟล์อื่นๆ เพื่อให้สามารถใช้งานได้) ---
// ในโปรเจกต์จริง คุณควรพิจารณาเก็บค่าคงที่เหล่านี้ไว้ในไฟล์ constants กลาง
const Color kBackgroundColor = Color(0xFFF5F5F5); 
const Color kPrimaryColor = Color(0xFF80CBC4);    
const Color kBlackText = Colors.black87;           

class KioskLandingScreen extends StatelessWidget {
  const KioskLandingScreen({super.key});

  // ฟังก์ชันสำหรับนำทางไปยังหน้าจอหลัก
  void _navigateToMainScreen(BuildContext context) {
    // ใช้ pushReplacement เพื่อไม่ให้ผู้ใช้สามารถกดปุ่มย้อนกลับจาก KioskMainScreen 
    // กลับมาที่หน้า Landing Page ได้
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const KioskMainScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      // ใช้ InkWell ครอบทั้ง body เพื่อให้ผู้ใช้สามารถแตะที่ไหนก็ได้บนหน้าจอเพื่อเริ่ม
      body: InkWell(
        onTap: () => _navigateToMainScreen(context), 
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(50.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Kiosk Logo/Icon Section
                const Icon(
                  Icons.recycling_rounded, // ไอคอนรีไซเคิล
                  size: 150,
                  color: kPrimaryColor,
                ),
                const SizedBox(height: 20),
                
                // Title
                Text(
                  'Welcome to The BottleBack',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: kPrimaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                
                // Subtitle/Instruction
                Text(
                  'Press START or Touch Anywhere to begin',
                  style: TextStyle(
                    fontSize: 20,
                    color: kBlackText.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 80),

                // START Button (ขนาดใหญ่พิเศษ)
                SizedBox(
                  width: size.width * 0.5, // กำหนดความกว้างของปุ่ม
                  height: 80,
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToMainScreen(context),
                    icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 35),
                    label: const Text(
                      'START',
                      style: TextStyle(
                        fontSize: 30, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}