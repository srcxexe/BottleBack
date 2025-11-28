import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Light Theme Constants ---
const Color kBackgroundColor = Color(0xFFF5F5F5);
const Color kSurfaceColor = Colors.white;
const Color kPrimaryColor = Color(0xFF00796B);
const Color kBlackText = Colors.black87;
const Color kGreyText = Colors.black54;

class BottleCountScreen extends StatefulWidget {
  const BottleCountScreen({Key? key}) : super(key: key);

  @override
  State<BottleCountScreen> createState() => _BottleCountScreenState();
}

class _BottleCountScreenState extends State<BottleCountScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  // คำนวณน้ำหนักจากจำนวนขวด (ตาม Logic ที่คุณแจ้ง: ให้คำนวณมาจากจำนวนขวด)
  double _calculateWeightFromCount(int count) {
    // สมมติค่าเฉลี่ย 0.04kg (40g) ต่อขวด
    return count * 0.04; 
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Scaffold(backgroundColor: kBackgroundColor, body: Center(child: Text("Login Required")));

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('My Inventory', style: TextStyle(color: kBlackText, fontWeight: FontWeight.bold, fontSize: 24)),
        backgroundColor: kSurfaceColor,
        elevation: 1,
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // ดึงข้อมูลจาก Wallet ของ Seller (Stock ปัจจุบันที่ได้จาก Kiosk)
        stream: FirebaseFirestore.instance.collection('sellers').doc(user!.uid).snapshots(),
        builder: (context, snapshot) {
          int totalBottles = 0;
          double calculatedWeight = 0.0;

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            totalBottles = (data['totalBottles'] ?? 0) as int;
            calculatedWeight = _calculateWeightFromCount(totalBottles);
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                 // --- 2 BOXES LAYOUT Only ---
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Box 1: จำนวนขวดทั้งหมด (บน)
                      _buildInfoBox(
                        title: 'Total Bottles (Current Stock)',
                        value: '$totalBottles',
                        unit: 'Units',
                        icon: Icons.local_drink_rounded,
                        color: Colors.blue.shade700,
                      ),
                      
                      const SizedBox(height: 15), // ระยะห่างระหว่างกล่องบน-ล่าง
            
                      // Box 2: น้ำหนักรวม (ล่าง - คำนวณจากขวด)
                      _buildInfoBox(
                        title: 'Total Weight (Calculated)',
                        value: calculatedWeight.toStringAsFixed(2),
                        unit: 'Kg',
                        icon: Icons.scale_rounded,
                        color: Colors.orange.shade700,
                      ),
                    ],
                  ),
                ),
                
                // ส่วน History ถูกลบออกแล้วตามคำขอ เพื่อลดความซ้ำซ้อนกับหน้า History หลัก
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget สำหรับสร้างกล่องบน-ล่าง
  Widget _buildInfoBox({required String title, required String value, required String unit, required IconData icon, required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1), 
            blurRadius: 15, 
            offset: const Offset(0, 5)
          )
        ],
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kGreyText)),
              const SizedBox(height: 5),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(width: 8),
                  Text(unit, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color.withOpacity(0.7))),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
        ],
      ),
    );
  }
}