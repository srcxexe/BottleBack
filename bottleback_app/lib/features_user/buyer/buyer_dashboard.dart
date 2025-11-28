import 'package:flutter/material.dart';
import 'buyer_home.dart'; 
import 'buyer_profile.dart'; 

// --- Light Theme Constants (Match Seller Theme) ---
const Color kBackgroundColor = Color(0xFFF5F5F5); // พื้นหลังสว่างมาก
const Color kSurfaceColor = Colors.white;          // สี Card/พื้นผิว
const Color kPrimaryColor = Color(0xFF00796B);    // สีเขียวหลัก (Dark Teal)

class BuyerDashboard extends StatefulWidget {
  const BuyerDashboard({Key? key}) : super(key: key);

  @override
  State<BuyerDashboard> createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const BuyerHomeScreen(),     
    const BuyerProfileScreen(),  
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: _screens[_currentIndex], 
      
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: kSurfaceColor, // พื้นผิวสว่าง
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
          selectedItemColor: kPrimaryColor,
          unselectedItemColor: Colors.grey,
          backgroundColor: kSurfaceColor, // พื้นหลังสีขาว
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_rounded),
              label: 'Requests',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}