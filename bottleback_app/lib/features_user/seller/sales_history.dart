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
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text('History', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBlackText)),
        automaticallyImplyLeading: false,
      ),
      body: user == null
        ? const Center(child: Text('Please Login', style: TextStyle(color: kBlackText)))
        : StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('sale_requests')
                .where('sellerId', isEqualTo: user.uid)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
              if (snapshot.data!.docs.isEmpty) return const Center(child: Text('No history found', style: TextStyle(color: kGreyText)));

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final id = doc.id;
                  
                  String dateStr = 'Unknown Date';
                  if (data['timestamp'] != null) {
                    dateStr = DateFormat('dd MMM yyyy, HH:mm').format((data['timestamp'] as Timestamp).toDate());
                  }
                  
                  final status = data['status'] ?? 'Pending';
                  final money = (data['money'] ?? 0).toDouble();
                  final type = data['type'] ?? 'Online Sale'; 

                  return _buildHistoryItem(context, id, dateStr, status, money, type);
                },
              );
            },
          ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, String id, String date, String status, double money, String type) {
    Color statusColor = Colors.orange;
    Color statusBg = Colors.orange.withOpacity(0.1);
    
    if (status == 'Completed' || status == 'Paid') {
      statusColor = kPrimaryColor;
      statusBg = kPrimaryColor.withOpacity(0.1);
    } else if (status == 'Rejected') {
      statusColor = Colors.red;
      statusBg = Colors.red.withOpacity(0.1);
    }

    // *** ตรวจสอบว่าเป็น Kiosk หรือไม่ ***
    bool isKiosk = type == 'Kiosk';
    IconData icon = isKiosk ? Icons.storefront_rounded : Icons.receipt_long_rounded;
    String title = isKiosk ? 'Kiosk Deposit' : 'Sale Request';
    Color iconBg = isKiosk ? Colors.purple.withOpacity(0.1) : kPrimaryColor.withOpacity(0.1);
    Color iconColor = isKiosk ? Colors.purple : kPrimaryColor;

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryDetailScreen(historyId: id)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  height: 50, width: 50,
                  decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kBlackText)),
                    const SizedBox(height: 4),
                    Text(date, style: const TextStyle(color: kGreyText, fontSize: 12)),
                    if (isKiosk) ...[
                      const SizedBox(height: 2),
                      Text('Instant Completed', style: TextStyle(color: iconColor, fontSize: 10, fontWeight: FontWeight.bold)),
                    ]
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('+ ฿${money.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kBlackText)),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
                  child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}