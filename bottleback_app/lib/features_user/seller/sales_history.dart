import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 
// ต้องเพิ่ม package intl ใน pubspec.yaml

// --- Constants ---
const Color kBackgroundColor = Color(0xFFB2F5E6);
const Color kPrimaryColor = Color(0xFF00BFA5);

class SalesHistoryScreen extends StatelessWidget {
  const SalesHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text(
          'Sales History',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        automaticallyImplyLeading: false, 
      ),
      body: user == null
          ? const Center(child: Text('Please log in to view history.'))
          : StreamBuilder<QuerySnapshot>(
              // Query: ดึงประวัติการขายของ Seller คนนี้ เรียงจากใหม่ไปเก่า
              stream: FirebaseFirestore.instance
                  .collection('sales_history')
                  .where('sellerId', isEqualTo: user.uid) // กรองตามผู้ขายปัจจุบัน
                  .orderBy('timestamp', descending: true) // เรียงจากใหม่สุด
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  // ข้อความแนะนำเมื่อเกิดข้อผิดพลาด (มักเกิดจากต้องสร้าง Index ใน Firestore Console)
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'Error: ${snapshot.error}. Please check the Firebase Console for missing index on sellerId + timestamp query.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_basket_outlined, size: 60, color: Colors.grey),
                        SizedBox(height: 10),
                        Text(
                          'No sales recorded yet.',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    final totalMoney = data['totalMoney'] ?? 0.0;
                    final timestamp = data['timestamp'] as Timestamp?;
                    
                    String dateString = 'Date N/A';
                    if (timestamp != null) {
                      final dateTime = timestamp.toDate();
                      // รูปแบบ: 19 Oct 2025, 23:45
                      dateString = DateFormat('dd MMM yyyy, HH:mm').format(dateTime); 
                    }

                    return _buildHistoryItem(totalMoney.toDouble(), dateString);
                  },
                );
              },
            ),
    );
  }

  // Widget สำหรับแสดงแต่ละรายการประวัติการขาย (ใช้ดีไซน์ Card ที่เข้ากับ UI อื่นๆ)
  Widget _buildHistoryItem(double money, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon และข้อมูลวัน/เวลา
          Expanded(
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline, 
                  color: kPrimaryColor,
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
          ),

          // ยอดเงินที่ขายได้
          Text(
            '+ ฿ ${money.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: kPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
}