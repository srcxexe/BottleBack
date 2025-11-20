import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'history_detail.dart';

const Color kBackgroundColor = Color(0xFF121212);
const Color kSurfaceColor = Color(0xFF1E1E1E);
const Color kPrimaryColor = Color(0xFF00BFA5);
const Color kWhiteText = Colors.white;

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
        title: const Text('History', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kWhiteText)),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('sale_requests')
            .where('sellerId', isEqualTo: user?.uid).orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text('No history yet', style: TextStyle(color: Colors.grey)));

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

    Color statusColor;
    Color statusBg;
    switch (status) {
      case 'Completed': statusColor = Colors.greenAccent; statusBg = Colors.green.withOpacity(0.2); break;
      case 'Rejected': statusColor = Colors.redAccent; statusBg = Colors.red.withOpacity(0.2); break;
      default: statusColor = Colors.orangeAccent; statusBg = Colors.orange.withOpacity(0.2);
    }

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HistoryDetailScreen(historyId: id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kSurfaceColor, // Dark Card
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  height: 50, width: 50,
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15)),
                  child: const Icon(Icons.receipt_long_rounded, color: Colors.white70),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sale Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kWhiteText)),
                    const SizedBox(height: 4),
                    Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('+ ฿${money.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kWhiteText)),
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
  }
}