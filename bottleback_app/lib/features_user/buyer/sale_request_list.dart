import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'request_detail_screen.dart'; // ใช้สำหรับการนำทางไปดูรายละเอียด

// --- Constants (สีเดียวกับ Dashboard) ---\
const Color kBackgroundColor = Color(0xFFB2F5E6); 
const Color kPrimaryColor = Color(0xFF00BFA5); 
const Color kDarkTextColor = Colors.black87;

class SaleRequestListScreen extends StatelessWidget {
  const SaleRequestListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text(
          'Sale Requests',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: kDarkTextColor,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // ดึงข้อมูลคำร้องขายทั้งหมดจาก Firestore
        stream: FirebaseFirestore.instance
            .collection('sale_requests') 
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final requests = snapshot.data?.docs ?? [];

          if (requests.isEmpty) {
            return const Center(
              child: Text(
                'No pending sale requests.', 
                style: TextStyle(fontSize: 18, color: Colors.grey)
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15.0),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final requestDoc = requests[index];
              final data = requestDoc.data() as Map<String, dynamic>;
              
              final requestId = requestDoc.id;
              final totalMoney = (data['totalMoney'] ?? 0.0).toDouble();
              final totalWeight = (data['totalWeight'] ?? 0.0).toDouble();
              final timestamp = data['timestamp'] as Timestamp?;
              final status = data['status'] ?? 'Pending'; // Pending, Paid, Completed

              String dateString = timestamp != null 
                  ? DateFormat('dd MMM yyyy, HH:mm').format(timestamp.toDate()) 
                  : 'N/A';
              
              return _buildRequestItem(
                context,
                requestId: requestId,
                money: totalMoney,
                weight: totalWeight,
                date: dateString,
                status: status,
              );
            },
          );
        },
      ),
    );
  }

  // Widget สำหรับแต่ละรายการคำร้อง
  Widget _buildRequestItem(
    BuildContext context, {
    required String requestId,
    required double money,
    required double weight,
    required String date,
    required String status,
  }) {
    // กำหนดสีตามสถานะ
    Color statusColor;
    if (status == 'Paid') {
      statusColor = Colors.green.shade700;
    } else if (status == 'Pending') {
      statusColor = kPrimaryColor;
    } else {
      statusColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () {
        // นำทางไปยังหน้ารายละเอียดคำร้อง
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RequestDetailScreen(requestId: requestId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 3),
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
                  'Total: ฿ ${money.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.scale, size: 16, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                  'Weight: ${weight.toStringAsFixed(3)} kg',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const Spacer(),
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                  date,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}