import 'package:flutter/material.dart';
import 'buyer_home.dart'; 
import 'buyer_profile.dart'; 

// --- Light Theme Constants ---
const Color kBackgroundColor = Color(0xFFF5F5F5); 
const Color kSurfaceColor = Colors.white;          
const Color kPrimaryColor = Color(0xFF00796B);    
const Color kSecondaryColor = Color(0xFF80CBC4);  
const Color kBlackText = Colors.black87;           
const Color kGreyText = Colors.black54;            

class BuyerDashboard extends StatefulWidget {
  const BuyerDashboard({Key? key}) : super(key: key);

  @override
  State<BuyerDashboard> createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const BuyerHomeScreen(),     // Index 0: Sale Requests List
    const BuyerProfileScreen(),  // Index 1: Profile
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor, // Light background
      body: _screens[_currentIndex], 
      
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: kSurfaceColor, // White Nav Bar background
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, -2))], // Subtle shadow
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
          selectedItemColor: kPrimaryColor, // Primary color selected
          unselectedItemColor: kGreyText,    // Dark grey unselected
          backgroundColor: kSurfaceColor, 
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          showUnselectedLabels: false,
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