import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bottle_count.dart'; 
import 'sales_history.dart'; 
import 'profile.dart'; 

// --- Light Theme Constants ---
const Color kBackgroundColor = Color(0xFFF5F5F5); 
const Color kSurfaceColor = Colors.white;          
const Color kPrimaryColor = Color(0xFF00796B);    
const Color kSecondaryColor = Color(0xFF80CBC4);  
const Color kBlackText = Colors.black87;           
const Color kGreyText = Colors.black54;            

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({Key? key}) : super(key: key);

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const DashboardHome(),
    const BottleCountScreen(),
    const SalesHistoryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: kSurfaceColor,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: kPrimaryColor,
          unselectedItemColor: Colors.grey,
          backgroundColor: kSurfaceColor,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.scale_rounded), label: 'Inventory'),
            BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class DashboardHome extends StatefulWidget {
  const DashboardHome({Key? key}) : super(key: key);

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  // ตัวแปรสำหรับเก็บจำนวนขวดแต่ละประเภท
  int _petCount = 0;
  int _hdpeCount = 0;
  int _canCount = 0;
  int _glassCount = 0;
  
  double _totalEstimatedValue = 0.0;

  // --- 1. กำหนดน้ำหนักต่อหน่วย (kg) ---
  final Map<String, double> _weightPerUnit = {
    'PET': 0.035,
    'HDPE': 0.040,
    'CAN': 0.015,
    'GLASS': 0.200,
  };

  // --- 2. กำหนดราคาต่อกิโลกรัม (Baht/kg) ---
  final double _petPricePerKg = 10.0;   
  final double _hdpePricePerKg = 12.0;
  final double _canPricePerKg = 40.0;
  final double _glassPricePerKg = 2.0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance.collection('sellers').doc(user.uid).snapshots().listen((doc) {
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _petCount = data['petCount'] ?? 0;
          _hdpeCount = data['hdpeCount'] ?? 0;
          _canCount = data['canCount'] ?? 0;
          _glassCount = data['glassCount'] ?? 0;

          // --- คำนวณมูลค่ารวมตามน้ำหนัก ---
          double petWeight = _petCount * (_weightPerUnit['PET']!);
          double hdpeWeight = _hdpeCount * (_weightPerUnit['HDPE']!);
          double canWeight = _canCount * (_weightPerUnit['CAN']!);
          double glassWeight = _glassCount * (_weightPerUnit['GLASS']!);

          _totalEstimatedValue = (petWeight * _petPricePerKg) + 
                                 (hdpeWeight * _hdpePricePerKg) + 
                                 (canWeight * _canPricePerKg) + 
                                 (glassWeight * _glassPricePerKg);
        });
      }
    });
  }

  void _showConfirmSaleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Sale Request'),
        content: const Text('Do you want to sell all current inventory?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => _createSaleRequest(),
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _createSaleRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
        Navigator.pop(context); // ปิด Dialog
        
        // คำนวณน้ำหนักและราคาของแต่ละประเภทเพื่อบันทึก
        double petW = _petCount * _weightPerUnit['PET']!;
        double hdpeW = _hdpeCount * _weightPerUnit['HDPE']!;
        double canW = _canCount * _weightPerUnit['CAN']!;
        double glassW = _glassCount * _weightPerUnit['GLASS']!;

        // สร้างรายการขาย
        await FirebaseFirestore.instance.collection('sale_requests').add({
          'sellerId': user.uid,
          'items': [
            {
              'bottleType': 'PET', 
              'count': _petCount, 
              'weight': petW,
              'pricePerKg': _petPricePerKg, 
              'subTotal': petW * _petPricePerKg
            },
            {
              'bottleType': 'HDPE', 
              'count': _hdpeCount, 
              'weight': hdpeW,
              'pricePerKg': _hdpePricePerKg, 
              'subTotal': hdpeW * _hdpePricePerKg
            },
            {
              'bottleType': 'CAN', 
              'count': _canCount, 
              'weight': canW,
              'pricePerKg': _canPricePerKg, 
              'subTotal': canW * _canPricePerKg
            },
            {
              'bottleType': 'GLASS', 
              'count': _glassCount, 
              'weight': glassW,
              'pricePerKg': _glassPricePerKg, 
              'subTotal': glassW * _glassPricePerKg
            },
          ],
          'money': _totalEstimatedValue,
          'totalWeight': petW + hdpeW + canW + glassW,
          'status': 'Pending',
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'Online Sale',
        });

        // ล้าง Inventory
        await FirebaseFirestore.instance.collection('sellers').doc(user.uid).update({
          'petCount': 0,
          'hdpeCount': 0,
          'canCount': 0,
          'glassCount': 0,
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sale request created successfully!')));

    } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // คำนวณมูลค่าเฉพาะ PET เพื่อแสดงผลในหน้า Dashboard (ตามคำขอเดิมที่ให้โชว์แค่ PET)
    double petWeight = _petCount * (_weightPerUnit['PET']!);
    double petValue = petWeight * _petPricePerKg;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                     Text('Welcome Back,', style: TextStyle(fontSize: 16, color: kGreyText)),
                     Text('Seller Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBlackText)),
                  ],
                ),
                CircleAvatar(backgroundColor: kPrimaryColor.withOpacity(0.1), child: const Icon(Icons.person, color: kPrimaryColor)),
              ],
            ),
            const SizedBox(height: 30),

            // Summary Card (Total Value)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [kPrimaryColor, kSecondaryColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: kPrimaryColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text('Total Inventory Value', style: TextStyle(color: Colors.white70, fontSize: 16)),
                   const SizedBox(height: 10),
                   Text('฿${_totalEstimatedValue.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 10),
                   const Text('Ready to cash out?', style: TextStyle(color: Colors.white, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Inventory Breakdown (แสดงเฉพาะ PET)
            const Text('Inventory Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBlackText)),
            const SizedBox(height: 15),
            
            // แสดงยอดเงินที่จะขายได้จาก PET (คำนวณแบบใหม่)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on_rounded, color: kPrimaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Estimated Value: ฿${petValue.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // แสดงเฉพาะ PET Card พร้อมน้ำหนัก
            SizedBox(
              height: 120,
              width: double.infinity,
              child: _buildStatCard(
                'PET', 
                _petCount, 
                petWeight, // ส่งน้ำหนักไปแสดง
                Icons.local_drink_rounded, 
                Colors.orange
              ),
            ),

            const SizedBox(height: 30),
            
            // ปุ่มขาย
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _totalEstimatedValue > 0 ? _showConfirmSaleDialog : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBlackText,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                child: const Text('Confirm Sale Request', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, double weight, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kGreyText)),
              const SizedBox(height: 5),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('$count Units', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBlackText)),
                  const SizedBox(width: 8),
                  // แสดงน้ำหนักข้างๆ
                  Text(
                    '(${weight.toStringAsFixed(2)} kg)', 
                    style: const TextStyle(fontSize: 14, color: kGreyText)
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}