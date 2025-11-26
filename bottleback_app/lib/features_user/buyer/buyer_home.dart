import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'request_detail_screen.dart'; // <<< ต้องมีไฟล์นี้อยู่

// --- Light Theme Constants ---
const Color kBackgroundColor = Color(0xFFF5F5F5); // พื้นหลังสว่างมาก (เกือบขาว)
const Color kSurfaceColor = Colors.white;          // สี Card, Nav Bar (ขาว)
const Color kPrimaryColor = Color(0xFF00796B);    // สีเขียวเข้ม (Dark Teal)
const Color kSecondaryColor = Color(0xFF80CBC4);  // สีเขียวอ่อน (Light Teal)
const Color kBlackText = Colors.black87;           // สีตัวอักษรเข้ม
const Color kGreyText = Colors.black54;            // สีตัวอักษรรอง

class BuyerHomeScreen extends StatelessWidget {
  const BuyerHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('Please log in to view requests.', style: TextStyle(color: kBlackText)));
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text(
          'Sale Requests',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBlackText),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // FIX: ดึงรายการทั้งหมด (ไม่กรองด้วย buyerId)
        stream: FirebaseFirestore.instance
            .collection('sale_requests') 
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red))); 
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No sale requests found.', style: TextStyle(color: kGreyText)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildRequestItem(context, doc.id, data);
            },
          );
        },
      ),
    );
  }
  
  Widget _buildRequestItem(BuildContext context, String id, Map<String, dynamic> data) {
    final status = data['status'] ?? 'Pending';
    final money = (data['totalMoney'] ?? 0.0).toDouble();
    final weight = (data['totalWeight'] ?? 0.0).toDouble();
    final date = data['timestamp'] != null
        ? DateFormat('dd MMM, HH:mm').format((data['timestamp'] as Timestamp).toDate()) : '-';
    
    Color statusColor;
    Color statusBg;
    switch (status) {
      case 'Completed': statusColor = Colors.green.shade800; statusBg = Colors.green.shade50; break;
      case 'Rejected': statusColor = Colors.red.shade800; statusBg = Colors.red.shade50; break;
      case 'Paid': statusColor = Colors.blue.shade800; statusBg = Colors.blue.shade50; break;
      case 'In Progress': statusColor = Colors.purple.shade800; statusBg = Colors.purple.shade50; break;
      default: statusColor = kPrimaryColor; statusBg = kSecondaryColor.withOpacity(0.3);
    }

    return GestureDetector( // <<< FIX 2: เพิ่ม GestureDetector
      onTap: () {
        // นำทางไปหน้าจอรายละเอียด (สำหรับ Buyer)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => RequestDetailScreen(requestId: id), // ส่ง Document ID ไป
          ),
        ); 
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  data['sellerName'] ?? 'Unknown Seller',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kBlackText),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(color: kBackgroundColor, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.scale, size: 16, color: kGreyText),
                const SizedBox(width: 5),
                Text(
                  'Weight: ${weight.toStringAsFixed(3)} kg',
                  style: const TextStyle(fontSize: 14, color: kGreyText),
                ),
                const Spacer(),
                const Icon(Icons.calendar_today, size: 14, color: kGreyText),
                const SizedBox(width: 5),
                Text(
                  date,
                  style: const TextStyle(fontSize: 12, color: kGreyText),
                ),
                const SizedBox(width: 8),
                Text(
                  '฿${money.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14, color: kGreyText),
              ],
            ),
          ],
        ),
      ),
    );
  }
}