import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Light Theme Constants ---
const Color kBackgroundColor = Color(0xFFF5F5F5); 
const Color kSurfaceColor = Colors.white;          
const Color kPrimaryColor = Color(0xFF00796B);    
const Color kSecondaryColor = Color(0xFF80CBC4);
const Color kBlackText = Colors.black87;           
const Color kGreyText = Colors.black54;            

class BottleCountScreen extends StatefulWidget {
  const BottleCountScreen({Key? key}) : super(key: key);

  @override
  State<BottleCountScreen> createState() => _BottleCountScreenState();
}

class _BottleCountScreenState extends State<BottleCountScreen> {
  // --- 1. กำหนดน้ำหนักต่อหน่วย (kg) ---
  final double _petWeightPerUnit = 0.035;

  // --- 2. กำหนดราคาต่อกิโลกรัม (Baht/kg) ---
  final double _petPricePerKg = 10.0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text('My Inventory', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBlackText)),
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('sellers').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No inventory data found', style: TextStyle(color: kGreyText)));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          
          // ดึงข้อมูลจำนวนขวด (เฉพาะ PET)
          final int petCount = data['petCount'] ?? 0;
          
          // --- คำนวณมูลค่าตามน้ำหนัก ---
          final double petWeight = petCount * _petWeightPerUnit;
          final double petValue = petWeight * _petPricePerKg;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // แสดงยอดเงินในรูปแบบ Card (สีเขียวหลัก)
              _buildValueCard(petValue),

              // แสดงการ์ด PET Bottles
              _buildInventoryCard(
                'PET Bottles', 
                petCount, 
                petWeight,
                Icons.local_drink_rounded, 
                Colors.orange
              ),
            ],
          );
        },
      ),
    );
  }

  // Widget แสดงมูลค่าเงิน (ดีไซน์ใหม่ให้เหมือน Inventory Card แต่เป็นสีเขียว)
  Widget _buildValueCard(double value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kPrimaryColor, // ใช้สีเขียวหลักเป็นพื้นหลัง
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: kPrimaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2), // พื้นหลังไอคอนจางๆ
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.monetization_on_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Estimated Value', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70)
              ),
              const SizedBox(height: 5),
              Text(
                '฿${value.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(String title, int count, double weight, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBlackText)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Text('In Stock: ', style: TextStyle(fontSize: 12, color: kGreyText)),
                    Text('${weight.toStringAsFixed(2)} kg', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kGreyText)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$count',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kPrimaryColor),
              ),
              const Text('units', style: TextStyle(fontSize: 14, color: kGreyText, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}