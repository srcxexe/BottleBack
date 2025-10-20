import 'package:flutter/material.dart';

// **สำคัญ:** แก้ไขพาธเหล่านี้ให้ชี้ไปยังไฟล์ที่ถูกต้องในโปรเจกต์ของคุณ
import 'buyer_home.dart'; 
import 'buyer_profile.dart'; 

// --- Constants (ใช้สีเดียวกันกับโปรเจกต์) ---
const Color kBackgroundColor = Color(0xFFB2F5E6); 
const Color kPrimaryColor = Color(0xFF00BFA5); 

// --------------------------------------------------------------------------
// 1. Buyer Dashboard (จัดการ Bottom Navigation)
// --------------------------------------------------------------------------

class BuyerDashboard extends StatefulWidget {
  const BuyerDashboard({Key? key}) : super(key: key);

  @override
  State<BuyerDashboard> createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard> {
  int _currentIndex = 0;
  
  // ลิสต์ของหน้าจอที่ใช้ในการสลับ
  final List<Widget> _screens = [
    const BuyerHomeScreen(),     // Index 0: หน้าหลัก (Sale Requests)
    const BuyerProfileScreen(),  // Index 1: หน้าโปรไฟล์
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ตัว Body แสดงหน้าจอตาม Index ปัจจุบัน
      body: _screens[_currentIndex], 
      
      // Bottom Navigation Bar สำหรับสลับหน้าจอ
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        selectedItemColor: kPrimaryColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed, // ป้องกันการเปลี่ยนสีพื้นหลังเมื่อ Item เยอะ
        
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_rounded),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}