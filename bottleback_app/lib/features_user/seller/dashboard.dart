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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: kPrimaryColor,
          unselectedItemColor: Colors.grey,
          backgroundColor: kSurfaceColor,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.inventory_2_rounded), label: 'Inventory'),
            BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class DashboardHome extends StatelessWidget {
  const DashboardHome({Key? key}) : super(key: key);

  // ฟังก์ชันคำนวณน้ำหนักคร่าวๆ จากจำนวนขวด (ถ้าไม่มีข้อมูลน้ำหนักจริงจาก Kiosk)
  double _calculateEstimatedWeight(int count) {
    // สมมติเฉลี่ยขวดละ 0.04 กก. (40 กรัม)
    return count * 0.04;
  }

  // ฟังก์ชันขาย (ถอนเงิน)
  Future<void> _processSellRequest(BuildContext context, User user, int currentBottles, double currentBalance) async {
    if (currentBottles <= 0) return;

    // แสดง Dialog ยืนยัน
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Sale/Withdrawal'),
        content: Text('Sell all $currentBottles bottles for ฿${currentBalance.toStringAsFixed(2)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // ใช้ Transaction เพื่อความปลอดภัย: สร้าง Request -> ลบยอดใน Wallet
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentReference sellerRef = FirebaseFirestore.instance.collection('sellers').doc(user.uid);
        DocumentSnapshot sellerSnapshot = await transaction.get(sellerRef);

        if (!sellerSnapshot.exists) throw Exception("Seller data not found");

        // 1. สร้าง Sale Request ใหม่ (ส่งคำร้องไปฝั่ง Buy)
        DocumentReference newRequestRef = FirebaseFirestore.instance.collection('sale_requests').doc();
        transaction.set(newRequestRef, {
          'sellerId': user.uid,
          'sellerName': sellerSnapshot.get('name') ?? 'Unknown Seller',
          'items': [
            {'bottleType': 'Mixed (From Kiosk)', 'count': currentBottles, 'weightKg': _calculateEstimatedWeight(currentBottles)}
          ],
          'count': currentBottles,
          'weightKg': _calculateEstimatedWeight(currentBottles),
          'money': currentBalance, // ราคารวมที่ Kiosk คำนวณมาให้แล้ว
          'status': 'Pending', // รอการโอนเงินจาก Buyer
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'Wallet Withdrawal',
        });

        // 2. เคลียร์ยอดใน Wallet ของ Seller เป็น 0 (เพราะขายออกไปแล้วรอเงินเข้า)
        transaction.update(sellerRef, {
          'walletBalance': 0.0,
          'totalBottles': 0, // หรือฟิลด์ที่ Kiosk ใช้เก็บจำนวนขวดสะสม
        });
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale request sent! Waiting for payment.'), backgroundColor: kPrimaryColor),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Please Login", style: TextStyle(color: kBlackText)));

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kSurfaceColor,
        elevation: 1,
        title: const Text('Dashboard', style: TextStyle(color: kBlackText, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
      ),
      // Stream ข้อมูลจาก 'sellers' collection โดยตรง (กระเป๋าเงิน/สต็อกปัจจุบัน)
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('sellers').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          int currentBottles = 0;
          double currentWalletBalance = 0.0;
          double estimatedWeight = 0.0;

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            // ดึงข้อมูลจำนวนขวดและเงินที่สะสมจาก Kiosk
            currentBottles = (data['totalBottles'] ?? 0) as int; // ต้องตรวจสอบว่า Kiosk บันทึกฟิลด์นี้ไหม ถ้าไม่ อาจต้องแก้ Kiosk ให้บันทึกด้วย
            currentWalletBalance = (data['walletBalance'] ?? 0.0).toDouble();
            estimatedWeight = _calculateEstimatedWeight(currentBottles);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Current Wallet (From Kiosk)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBlackText)),
                const SizedBox(height: 5),
                const Text("Items collected from Kiosk ready to be sold.", style: TextStyle(fontSize: 14, color: kGreyText)),
                const SizedBox(height: 15),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Bottles in Stock',
                        value: '$currentBottles',
                        unit: 'Units',
                        icon: Icons.local_drink_rounded,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Est. Value',
                        value: currentWalletBalance.toStringAsFixed(2),
                        unit: 'THB',
                        icon: Icons.attach_money_rounded,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),
                const Text("Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBlackText)),
                const SizedBox(height: 15),

                // --- ปุ่ม Sell (Withdraw) ---
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: currentBottles > 0 
                      ? () => _processSellRequest(context, user, currentBottles, currentWalletBalance)
                      : null, // ปิดปุ่มถ้าไม่มีของ
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: currentBottles > 0 ? 5 : 0,
                    ),
                    icon: const Icon(Icons.sell_rounded, color: Colors.white, size: 28),
                    label: const Text(
                      'Sell All & Withdraw', 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
                    ),
                  ),
                ),
                if (currentBottles == 0)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Center(child: Text("Go to Kiosk to deposit bottles first.", style: TextStyle(color: kGreyText))),
                  ),

                const SizedBox(height: 15),
                
                _buildActionCard(
                  context, 
                  icon: Icons.history_rounded, 
                  title: 'View History', 
                  subtitle: 'Check past withdrawals status',
                  onTap: () {
                     // Navigate to history tab via controller (handled by parent usually)
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required String unit, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurfaceColor, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 15),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBlackText)),
          const SizedBox(height: 5),
          Text('$unit', style: const TextStyle(fontSize: 12, color: kGreyText)),
          const SizedBox(height: 5),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kGreyText)),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kPrimaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: kPrimaryColor),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBlackText)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: kGreyText)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}