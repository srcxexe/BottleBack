import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BottleCountScreen extends StatelessWidget {
  const BottleCountScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
                                           
    return Scaffold(
      backgroundColor: const Color(0xFFB2F5E6), // Setting a background color for the screen
      // --- ส่วนที่เพิ่มเข้ามา ---
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        // ปุ่มย้อนกลับ
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // หัวข้อของ AppBar
        title: const Text(
          'Bottles Count',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        titleSpacing: 0, // ทำให้หัวข้อชิดกับปุ่มย้อนกลับมากขึ้น
      ),
      // --------------------
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('sellers')
              .doc(user!.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data?.data() == null) {
              return const Center(child: Text("No data found."));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            
            // ข้อมูลขวดแต่ละประเภท
            final petCount = data['petCount'] ?? 0;
            final hdpeCount = data['hdpeCount'] ?? 0;
            final canCount = data['canCount'] ?? 0;

            final petWeight = (data['petWeight'] ?? 0.0).toDouble();
            final hdpeWeight = (data['hdpeWeight'] ?? 0.0).toDouble();
            final canWeight = (data['canWeight'] ?? 0.0).toDouble();

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- ส่วนที่ถูกลบออก ---
                    // Header (IconButton is removed as navigation is handled by BottomNav)
                    // const SizedBox(height: 20),
                    // Title
                    // const Text(
                    //   'Bottles Count',
                    //    ...
                    // ),
                    // --------------------
                    const SizedBox(height: 10), // ปรับระยะห่างด้านบน
                    // PET Bottle Card
                    _buildBottleCard(
                      type: 'PET Bottle',
                      count: petCount,
                      weight: petWeight,
                      color: Colors.white,
                      icon: Icons.local_drink_rounded,
                    ),
                    const SizedBox(height: 20),
                    // HDPE Bottle Card
                    _buildBottleCard(
                      type: 'HDPE Bottle',
                      count: hdpeCount,
                      weight: hdpeWeight,
                      color: Colors.white,
                      icon: Icons.water_drop_rounded,
                    ),
                    const SizedBox(height: 20),
                    // Can Card
                    _buildBottleCard(
                      type: 'Can',
                      count: canCount,
                      weight: canWeight,
                      color: Colors.white,
                      icon: Icons.recycling_rounded,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottleCard({
    required String type,
    required int count,
    required double weight,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF00BFA5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          // Type
          Text(
            type,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          // Count and Weight
          Row(
            // --- ส่วนที่แก้ไข ---
            children: [
              // ใช้ Expanded เพื่อให้ Widget แบ่งพื้นที่กันอัตโนมัติ
              Expanded(
                child: _buildInfoBox(
                  value: 'x$count',
                  label: 'bottles',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoBox(
                  value: '${weight.toStringAsFixed(1)}kg', // แก้ไข kg. เป็น kg
                  label: 'weight',
                ),
              ),
            ],
            // --------------------
          ),
        ],
      ),
    );
  }

  // --- Widget ใหม่ที่สร้างขึ้นเพื่อลดโค้ดซ้ำซ้อน ---
  Widget _buildInfoBox({required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16, // ลด Padding แนวนอนลงเล็กน้อย
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28, // ปรับขนาด Font ให้เหมาะสม
              fontWeight: FontWeight.bold,
              color: Colors.black,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

