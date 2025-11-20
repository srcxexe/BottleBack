import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'request_detail_screen.dart';

// --- Dark Theme Constants ---
const Color kBackgroundColor = Color(0xFF121212);
const Color kSurfaceColor = Color(0xFF1E1E1E);
const Color kPrimaryColor = Color(0xFF00BFA5);
const Color kWhiteText = Colors.white;

class BuyerHomeScreen extends StatelessWidget {
  const BuyerHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text(
          'Sale Requests',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kWhiteText),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sale_requests') 
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.grey)));
          }

          final requests = snapshot.data?.docs ?? [];

          if (requests.isEmpty) {
            return const Center(
              child: Text('No pending sale requests.', style: TextStyle(fontSize: 18, color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20.0),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final requestDoc = requests[index];
              final data = requestDoc.data() as Map<String, dynamic>;
              
              final requestId = requestDoc.id;
              final totalMoney = (data['totalMoney'] ?? 0.0).toDouble();
              final totalWeight = (data['totalWeight'] ?? 0.0).toDouble();
              final timestamp = data['timestamp'] as Timestamp?;
              final status = data['status'] ?? 'Pending'; 

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

  Widget _buildRequestItem(
    BuildContext context, {
    required String requestId,
    required double money,
    required double weight,
    required String date,
    required String status,
  }) {
    Color statusColor;
    Color statusBg;
    
    if (status == 'Paid' || status == 'Completed') {
      statusColor = Colors.greenAccent;
      statusBg = Colors.green.withOpacity(0.2);
    } else if (status == 'Pending') {
      statusColor = kPrimaryColor;
      statusBg = kPrimaryColor.withOpacity(0.15);
    } else {
      statusColor = Colors.grey;
      statusBg = Colors.grey.withOpacity(0.2);
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RequestDetailScreen(requestId: requestId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kSurfaceColor, // Dark Card
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: statusColor),
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
            Row(
              children: [
                const Icon(Icons.scale, size: 16, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                  'Weight: ${weight.toStringAsFixed(3)} kg',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
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