import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 
// import 'request_detail_screen.dart'; // ต้อง import หน้าจอรายละเอียด (สำหรับ Seller)

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
          'Sale Requests History',
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
              // *** ดึงข้อมูลจาก collection 'sale_requests' ที่มี sellerId ตรงกับ user ปัจจุบัน ***
              stream: FirebaseFirestore.instance
                  .collection('sale_requests')
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
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No sale requests found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    final money = (data['totalMoney'] ?? 0.0).toDouble();
                    final timestamp = data['timestamp'] as Timestamp?;
                    final status = data['status'] as String? ?? 'Unknown';

                    return _buildSaleHistoryCard(
                      context,
                      requestId: doc.id,
                      money: money,
                      timestamp: timestamp,
                      status: status, // ส่งสถานะไปแสดง
                    );
                  },
                );
              },
            ),
    );
  }

  // Widget สำหรับกำหนดสีและไอคอนตามสถานะ
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green.shade600; // ขายสำเร็จ
      case 'Rejected':
        return Colors.red.shade600; // ปฏิเสธการขาย
      case 'Pending':
      default:
        return Colors.blue.shade600; // ระหว่างดำเนินการ
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Completed':
        return Icons.check_circle_outline;
      case 'Rejected':
        return Icons.cancel_outlined;
      case 'Pending':
      default:
        return Icons.hourglass_top_outlined;
    }
  }
  
  // Widget Card เพื่อแสดงสถานะ
  Widget _buildSaleHistoryCard(
    BuildContext context, {
    required String requestId,
    required double money,
    required Timestamp? timestamp,
    required String status,
  }) {
    final date = timestamp != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(timestamp.toDate())
        : 'N/A';
    
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    // แปลงสถานะเป็นภาษาไทย
    final statusText = status == 'Completed' ? 'ขายสำเร็จ' : status == 'Rejected' ? 'ปฏิเสธการขาย' : 'ระหว่างดำเนินการ';

    return GestureDetector(
      onTap: () {
        // *** TODO: นำทางไปยังหน้ารายละเอียด RequestDetailScreen ***
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => RequestDetailScreen(requestId: requestId), 
        //   ),
        // );
        // หมายเหตุ: หน้าจอ RequestDetailScreen ที่ให้ไปก่อนหน้าถูกออกแบบมาสำหรับ Buyer
        // แต่ Seller สามารถใช้หน้าจอที่คล้ายกันเพื่อดูรายละเอียดได้ (โดยไม่ต้องมีปุ่ม Confirm/Reject)
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 30),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText, // แสดงสถานะ
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: statusColor,
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
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: statusColor, 
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}