import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 
import '../seller/history_detail.dart'; // <<< ต้องมีไฟล์นี้อยู่ (ชื่อ HistoryDetailScreen)

// --- Dark Theme Constants (อ้างอิงจากไฟล์ Seller อื่นๆ) ---
const Color kBackgroundColor = Color(0xFF121212); 
const Color kSurfaceColor = Color(0xFF1E1E1E);    
const Color kPrimaryColor = Color(0xFF00BFA5);    
const Color kWhiteText = Colors.white;           
const Color kGreyText = Colors.white70;

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
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kWhiteText), // White text
        ),
        automaticallyImplyLeading: false, 
      ),
      body: user == null
          ? const Center(child: Text('Please log in to view history.', style: TextStyle(color: kGreyText)))
          : StreamBuilder<QuerySnapshot>(
              // FIX: กรองด้วย sellerId เพื่อให้ Security Rules อนุญาตและแสดงเฉพาะประวัติของตัวเอง
              stream: FirebaseFirestore.instance
                  .collection('sale_requests')
                  .where('sellerId', isEqualTo: user.uid) 
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text('No sale requests found.', style: TextStyle(color: kGreyText)));

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildHistoryItem(context, doc.id, data);
                  },
                );
              },
            ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, String id, Map<String, dynamic> data) {
    final status = data['status'] ?? 'Pending';
    final money = (data['totalMoney'] ?? 0.0).toDouble();
    final date = data['timestamp'] != null 
        ? DateFormat('dd MMM, HH:mm').format((data['timestamp'] as Timestamp).toDate()) : '-';
    final sellerName = data['sellerName'] ?? 'N/A';
    final buyerName = data['buyerName'] ?? 'N/A';

    Color statusColor;
    Color statusBg;
    IconData statusIcon;
    switch (status) {
      case 'Completed': statusColor = Colors.green.shade500; statusBg = Colors.green.shade900.withOpacity(0.3); statusIcon = Icons.check_circle_rounded; break;
      case 'Rejected': statusColor = Colors.red.shade400; statusBg = Colors.red.shade900.withOpacity(0.3); statusIcon = Icons.cancel_rounded; break;
      case 'Paid': statusColor = Colors.blue.shade400; statusBg = Colors.blue.shade900.withOpacity(0.3); statusIcon = Icons.paid_rounded; break;
      case 'In Progress': statusColor = Colors.purple.shade400; statusBg = Colors.purple.shade900.withOpacity(0.3); statusIcon = Icons.cached_rounded; break;
      default: statusColor = kPrimaryColor; statusBg = kPrimaryColor.withOpacity(0.3); statusIcon = Icons.hourglass_top_rounded; 
    }

    return GestureDetector( // <<< FIX 2: เพิ่ม GestureDetector
      onTap: () {
        // นำทางไปหน้าจอรายละเอียดประวัติการขาย (สำหรับ Seller)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => HistoryDetailScreen(historyId: id), // ส่ง Document ID ไป
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kSurfaceColor, 
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))], 
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 28),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request to $buyerName', 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kWhiteText), 
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: const TextStyle(fontSize: 12, color: kGreyText), 
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
                const Icon(Icons.arrow_forward_ios, size: 16, color: kGreyText), 
              ],
            ),
          ],
        ),
      ),
    );
  }
}