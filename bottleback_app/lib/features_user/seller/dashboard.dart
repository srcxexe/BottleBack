import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ต้อง import หน้าจออื่นๆ เข้ามา
import 'bottle_count.dart'; 
import 'sales_history.dart'; 
import 'profile.dart'; 

// --- Constants ---
const Color kBackgroundColor = Color(0xFFB2F5E6);
const Color kPrimaryColor = Color(0xFF00BFA5);

// --------------------------------------------------------------------------
// 1. Seller Dashboard (จัดการ Bottom Navigation)
// --------------------------------------------------------------------------

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({Key? key}) : super(key: key);

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  int _currentIndex = 0;
  String _userName = 'Loading...';
  Map<String, dynamic> _sellerData = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ดึงข้อมูลผู้ใช้เพื่อใช้ใน initState (สำหรับแสดงชื่อ)
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('sellers')
          .doc(user.uid)
          .get();
      
      if (doc.exists) {
        setState(() {
          _sellerData = doc.data() ?? {};
          _userName = _sellerData['name'] ?? 'User';
        });
      }
    }
  }

  // *** List หน้าจอที่สมบูรณ์ (4 องค์ประกอบ) เพื่อให้ Navbar ทำงานครบทุกปุ่ม ***
  final List<Widget> _screens = const [
    DashboardHome(),      // Index 0: Home
    BottleCountScreen(),  // Index 1: Add/Stock
    SalesHistoryScreen(), // Index 2: Shopping Cart (History)
    ProfileScreen(),      // Index 3: Person (Profile)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      // แสดงหน้าจอตาม Index ที่เลือก
      body: _screens[_currentIndex], 
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_rounded, 0),
                _buildNavItem(Icons.add_circle_outline_rounded, 1),
                _buildNavItem(Icons.shopping_cart_rounded, 2), // History
                _buildNavItem(Icons.person_rounded, 3), // Profile
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget สำหรับปุ่มใน Bottom Navigation Bar
  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (index >= 0 && index < _screens.length) {
          setState(() => _currentIndex = index);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey,
          size: 28,
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// 2. Dashboard Home (หน้าจอหลัก)
// --------------------------------------------------------------------------

class DashboardHome extends StatelessWidget {
  const DashboardHome({Key? key}) : super(key: key);

  // ฟังก์ชันแสดง Dialog ยืนยันการขายและบันทึกข้อมูล
  void _showSellConfirmation(BuildContext context, double totalMoney, Map<String, dynamic> sellerData, User user) {
    if (totalMoney <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่มีขวดที่จะขาย')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'ยืนยันการขาย',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'คุณต้องการขายขวดและรับเงิน \$${totalMoney.toStringAsFixed(2)} หรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'ยกเลิก',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (user != null) {
                // *** ส่วนสำคัญ: บันทึกข้อมูล Breakdown ลงใน sales_history ***
                await FirebaseFirestore.instance
                    .collection('sales_history')
                    .add({
                  'sellerId': user.uid,
                  'totalMoney': totalMoney,
                  'timestamp': FieldValue.serverTimestamp(),
                  'petCount': sellerData['petCount'] ?? 0,
                  'hdpeCount': sellerData['hdpeCount'] ?? 0,
                  'canCount': sellerData['canCount'] ?? 0,
                  'petWeight': sellerData['petWeight'] ?? 0.0,
                  'hdpeWeight': sellerData['hdpeWeight'] ?? 0.0,
                  'canWeight': sellerData['canWeight'] ?? 0.0,
                });

                // รีเซ็ตข้อมูลสต็อกของผู้ขาย
                await FirebaseFirestore.instance
                    .collection('sellers')
                    .doc(user.uid)
                    .update({
                  'totalWeight': 0.0,
                  'totalMoney': 0.0,
                  'petCount': 0,
                  'hdpeCount': 0,
                  'canCount': 0,
                  'petWeight': 0.0,
                  'hdpeWeight': 0.0,
                  'canWeight': 0.0,
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ขายสำเร็จ!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'ยืนยัน',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('User not logged in.'));
    }

    return SafeArea(
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sellers')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final userName = data['name'] ?? 'User';
          final totalWeight = (data['totalWeight'] ?? 0.0).toDouble();
          final totalMoney = (data['totalMoney'] ?? 0.0).toDouble();

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 20),
                        onPressed: () {
                          // Back to role select or logout
                          FirebaseAuth.instance.signOut();
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Title
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hello, $userName',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Bottle Count Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bottle Count',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Column(
                            children: [
                              Text(
                                '${totalWeight.toStringAsFixed(1)} kg.',
                                style: const TextStyle(
                                  fontSize: 56,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  // Navigate to BottleCountScreen (Index 1)
                                  final sellerDashboardState = context.findAncestorStateOfType<_SellerDashboardState>();
                                  if (sellerDashboardState != null) {
                                    sellerDashboardState.setState(() {
                                      sellerDashboardState._currentIndex = 1;
                                    });
                                  } else {
                                     // Fallback navigation if not using the dashboard state
                                     Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const BottleCountScreen(),
                                        ),
                                     );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kBackgroundColor,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'See more',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward,
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Money Total Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Money Total',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Column(
                            children: [
                              Text(
                                '\$${totalMoney.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 56,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  // Call sell confirmation
                                  _showSellConfirmation(context, totalMoney, data, user);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kBackgroundColor,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Sell here',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}