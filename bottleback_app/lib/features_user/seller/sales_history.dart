import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'history_detail.dart';

// --- Light Theme Constants ---
const Color kBackgroundColor = Color(0xFFF5F5F5);
const Color kSurfaceColor = Colors.white;
const Color kPrimaryColor = Color(0xFF00796B);
const Color kBlackText = Colors.black87;
const Color kGreyText = Colors.black54;

class SalesHistoryScreen extends StatelessWidget {
  const SalesHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kSurfaceColor,
        elevation: 1,
        title: const Text('History', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBlackText)),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('sale_requests')
            .where('sellerId', isEqualTo: user?.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text('No history found', style: TextStyle(color: kGreyText)));

          final docs = snapshot.data!.docs;
          
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String docId = docs[index].id;
              
              // ตรวจสอบประเภทรายการ (Deposit = รับจาก Kiosk, Withdraw = ถอนเงิน/ขาย)
              String type = data['type'] ?? 'Withdraw'; // default เป็น Withdraw สำหรับข้อมูลเก่า
              bool isDeposit = type == 'Deposit';

              // การตั้งค่าสีและไอคอนตามประเภท
              Color cardColor = kSurfaceColor;
              IconData icon = isDeposit ? Icons.download_rounded : Icons.upload_rounded;
              Color iconBgColor = isDeposit ? Colors.green.shade50 : Colors.orange.shade50;
              Color iconColor = isDeposit ? Colors.green : Colors.orange;
              String title = isDeposit ? 'Received from Kiosk' : 'Sale Request';
              String amountPrefix = isDeposit ? '+' : ''; // ถ้าถอนอาจจะไม่ใส่เครื่องหมาย หรือใส่ - ก็ได้ตามชอบ

              Timestamp? ts = data['timestamp'];
              String date = ts != null 
                  ? DateFormat('dd MMM yyyy, HH:mm').format(ts.toDate()) 
                  : 'Unknown Date';
              
              double money = (data['money'] ?? 0).toDouble();
              String status = data['status'] ?? 'Pending';
              
              // สีสถานะ
              Color statusColor = Colors.grey;
              Color statusBg = Colors.grey.shade100;
              if (status == 'Completed' || status == 'Paid') {
                statusColor = Colors.green;
                statusBg = Colors.green.shade50;
              } else if (status == 'Pending') {
                statusColor = Colors.orange;
                statusBg = Colors.orange.shade50;
              }

              return InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => HistoryDetailScreen(historyId: docId)));
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        height: 50, width: 50,
                        decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(15)),
                        child: Icon(icon, color: iconColor),
                      ),
                      const SizedBox(width: 15),
                      
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kBlackText)),
                            const SizedBox(height: 4),
                            Text(date, style: const TextStyle(color: kGreyText, fontSize: 12)),
                          ],
                        ),
                      ),
                      
                      // Amount & Status
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('$amountPrefix ฿${money.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kBlackText)),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(10)),
                            child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}