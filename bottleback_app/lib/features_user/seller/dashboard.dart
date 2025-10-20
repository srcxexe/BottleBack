import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ต้อง import หน้าจออื่นๆ เข้ามา
import 'bottle_count.dart'; 
import 'sales_history.dart'; 
import 'profile.dart'; 

// --- Constants (ควรแยกไปไว้ในไฟล์ constants.dart หากโปรเจกต์ใหญ่ขึ้น) ---
const Color kBackgroundColor = Color(0xFFB2F5E6);
const Color kPrimaryColor = Color(0xFF00BFA5);
const Color kSecondaryColor = Color(0xFFFFCC80); // สีส้มอ่อนสำหรับเน้น
const Color kDarkTextColor = Colors.black87;

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
  
  late final List<Widget> _screens = [
    const DashboardHome(),
    const BottleCountScreen(),
    const SalesHistoryScreen(),
    const ProfileScreen(),
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
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        selectedItemColor: kPrimaryColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Count',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
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

// --------------------------------------------------------------------------
// 2. Dashboard Home Screen (หน้าหลัก)
// --------------------------------------------------------------------------

class DashboardHome extends StatefulWidget {
  const DashboardHome({Key? key}) : super(key: key);

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  String _userName = 'User';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('sellers')
          .doc(user.uid)
          .get();
      
      if (doc.exists && mounted) {
        setState(() {
          final data = doc.data() ?? {};
          _userName = data['name'] ?? 'User';
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } else if (mounted) {
       setState(() {
          _isLoading = false;
        });
    }
  }

  Future<void> _showConfirmSaleDialog(double totalMoney) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final doc = await FirebaseFirestore.instance.collection('sellers').doc(user.uid).get();
    final data = doc.data() as Map<String, dynamic>;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Confirm Sale'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Total Revenue: ฿ ${totalMoney.toStringAsFixed(2)}', 
                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 10),
                const Text('Do you want to confirm the sale and request payment? This action will reset your current inventory to zero.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              onPressed: () async {
                // บันทึกรายการขาย
                await FirebaseFirestore.instance.collection('sale_requests').add({
                  'sellerId': user.uid,
                  'totalMoney': totalMoney,
                  'totalWeight': data['totalWeight'] ?? 0.0,
                  'petCount': data['petCount'] ?? 0,
                  'hdpeCount': data['hdpeCount'] ?? 0,
                  'canCount': data['canCount'] ?? 0,
                  'petWeight': data['petWeight'] ?? 0.0,
                  'hdpeWeight': data['hdpeWeight'] ?? 0.0,
                  'canWeight': data['canWeight'] ?? 0.0,
                  'status': 'Pending',
                  'timestamp': FieldValue.serverTimestamp(),
                });

                // รีเซ็ตข้อมูล Inventory ของ Seller
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
                      content: Text('Sale Request Sent!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || _isLoading) {
      return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      // ไม่มี AppBar
      body: SafeArea( 
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0), 
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('sellers')
                .doc(user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
              }
              
              if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text('Error or user data not found.'));
              }
              
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final totalWeight = (data['totalWeight'] ?? 0.0).toDouble();
              final totalMoney = (data['totalMoney'] ?? 0.0).toDouble();
              final petCount = (data['petCount'] ?? 0);
              final hdpeCount = (data['hdpeCount'] ?? 0);
              final canCount = (data['canCount'] ?? 0);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20), 
                  
                  // Custom Header: Dashboard (ซ้าย) และ Hello User (ขวา)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Dashboard',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: kDarkTextColor,
                        ),
                      ),
                      Text(
                        'Hello, $_userName',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Summary Box (Total Revenue)
                  _buildSummaryBox(totalMoney, totalWeight, data),
                  const SizedBox(height: 20),

                  // Mini Summary Boxes (Count Breakdown) - แก้ไขให้เป็นแนวตั้ง
                  _buildMiniSummaryBoxes(petCount, hdpeCount, canCount),
                  const SizedBox(height: 20),
                  
                  // ปุ่ม Confirm Sale
                  _buildConfirmSaleButton(totalMoney),

                  const SizedBox(height: 20), 
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // Widget สำหรับ Summary Box หลัก (Total Revenue)
  Widget _buildSummaryBox(double totalMoney, double totalWeight, Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Inventory Value',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '฿ ${totalMoney.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          // ข้อมูลน้ำหนักรวม
          Row(
            children: [
              const Icon(Icons.scale, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                'Total Weight: ${totalWeight.toStringAsFixed(3)} kg',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // *** แก้ไข: Widget สำหรับ Mini Summary Boxes (เปลี่ยนจาก Grid เป็น Column) ***
  // --------------------------------------------------------------------------
  Widget _buildMiniSummaryBoxes(int petCount, int hdpeCount, int canCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Breakdown',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: kDarkTextColor,
          ),
        ),
        const SizedBox(height: 10),
        // เปลี่ยนจาก GridView.count เป็น Column เพื่อเรียง Card ลงมา
        Column( 
          children: [
            _buildMiniSummaryBox(
              title: 'PET',
              value: petCount.toString(),
              unit: 'units',
              icon: Icons.water_drop,
              color: Colors.blue.shade700,
            ),
            const SizedBox(height: 15), // ช่องว่างระหว่าง Card
            _buildMiniSummaryBox(
              title: 'HDPE',
              value: hdpeCount.toString(),
              unit: 'units',
              icon: Icons.recycling,
              color: Colors.green.shade700,
            ),
            const SizedBox(height: 15), // ช่องว่างระหว่าง Card
            _buildMiniSummaryBox(
              title: 'Can',
              value: canCount.toString(),
              unit: 'units',
              icon: Icons.sports_bar,
              color: Colors.red.shade700,
            ),
          ],
        ),
      ],
    );
  }
  // --------------------------------------------------------------------------

  // Widget สำหรับแต่ละ Box สรุปย่อย (ไม่มีการเปลี่ยนแปลง)
  Widget _buildMiniSummaryBox({
    required String title, 
    required String value, 
    required String unit, 
    required IconData icon,
    required Color color
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              Icon(icon, size: 20, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // Widget สำหรับปุ่มยืนยันการขาย (ไม่มีการเปลี่ยนแปลง)
  Widget _buildConfirmSaleButton(double totalMoney) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: totalMoney > 0
            ? () => _showConfirmSaleDialog(totalMoney)
            : null, 
        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
        label: const Text(
          'Confirm Sale Request',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 10,
        ),
      ),
    );
  }
}