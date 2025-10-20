import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 
// *** ตรวจสอบให้แน่ใจว่า import 'history_detail.dart' แล้ว ***
import 'history_detail.dart'; 

// --- Constants (อ้างอิงจาก dashboard.dart) ---
const Color kBackgroundColor = Color(0xFFB2F5E6); // *** สีพื้นหลังใหม่ ***
const Color kPrimaryColor = Color(0xFF00BFA5); // *** สีหลักใหม่ ***

class SalesHistoryScreen extends StatelessWidget {
  const SalesHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      // *** พื้นหลังของ Scaffold ใช้สีใหม่ ***
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        // *** พื้นหลัง AppBar ใช้สีใหม่ ***
        backgroundColor: Color(0xFFFFFFFF),
        elevation: 0,
        title: const Text(
          'Sales History',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            // ตัวอักษร Title เป็นสีดำ (ตัดกับพื้นหลังใหม่)
            color: Colors.black, 
          ),
        ),
        // ลบปุ่ม back ออกเพื่อให้เป็นหน้าหลักของ Bottom Nav
        automaticallyImplyLeading: false, 
      ),
      body: user == null
          ? const Center(child: Text('Please log in to view history.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sales_history')
                  .where('sellerId', isEqualTo: user.uid)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                
                final salesDocs = snapshot.data?.docs ?? [];

                if (salesDocs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off, size: 60, color: Colors.grey),
                        SizedBox(height: 10),
                        Text('No sales history found.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(15.0),
                  itemCount: salesDocs.length,
                  itemBuilder: (context, index) {
                    final saleDoc = salesDocs[index];
                    final saleData = saleDoc.data() as Map<String, dynamic>;
                    
                    final historyId = saleDoc.id;
                    final totalMoney = (saleData['totalMoney'] ?? 0.0).toDouble();
                    final timestamp = saleData['timestamp'] as Timestamp?;

                    String dateString = 'N/A';
                    if (timestamp != null) {
                      final DateFormat formatter = DateFormat('dd MMM yyyy, HH:mm');
                      dateString = formatter.format(timestamp.toDate());
                    }

                    return _buildHistoryItem(
                      context,
                      historyId: historyId,
                      money: totalMoney,
                      date: dateString,
                      // ใช้สีขาวสำหรับ Card เพื่อตัดกับพื้นหลังใหม่
                      cardColor: Colors.white,
                    );
                  },
                );
              },
            ),
    );
  }

  // Widget สำหรับแต่ละรายการประวัติการขาย
  Widget _buildHistoryItem(
    BuildContext context, {
    required String historyId,
    required double money,
    required String date,
    required Color cardColor,
  }) {
    return GestureDetector(
      onTap: () {
        // นำทางไปยังหน้ารายละเอียดเมื่อกด
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HistoryDetailScreen(historyId: historyId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: cardColor, // พื้นหลังรายการเป็นสีขาว
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ไอคอนและรายละเอียด
            Row(
              children: [
                const Icon(
                  Icons.check_circle_outline, 
                  color: kPrimaryColor, // ไอคอนใช้สีหลักใหม่
                  size: 30,
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sale Completed',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black, // ข้อความหลักเป็นสีดำ
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // ยอดเงินที่ขายได้
            Row(
              children: [
                Text(
                  '+ ฿ ${money.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: kPrimaryColor, // ยอดเงินใช้สีหลักใหม่
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}