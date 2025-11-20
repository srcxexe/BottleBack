import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

const Color kBackgroundColor = Color(0xFF121212);
const Color kSurfaceColor = Color(0xFF1E1E1E);
const Color kPrimaryColor = Color(0xFF00BFA5);
const Color kWhiteText = Colors.white;

class HistoryDetailScreen extends StatelessWidget {
  final String historyId;
  const HistoryDetailScreen({Key? key, required this.historyId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Transaction Details', style: TextStyle(color: kWhiteText, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: kBackgroundColor, elevation: 0, centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kWhiteText, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('sale_requests').doc(historyId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
          
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final totalMoney = (data['totalMoney'] ?? 0).toDouble();
          final status = data['status'] ?? 'Pending';
          List<Map<String, dynamic>> breakdown = [];
          if (data['breakdown'] != null) {
             breakdown = List<Map<String, dynamic>>.from((data['breakdown'] as List).map((item) => Map<String, dynamic>.from(item)));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                // Status & Amount Card
                Container(
                  padding: const EdgeInsets.all(30),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: kSurfaceColor,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: status == 'Completed' ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                        child: Icon(status == 'Completed' ? Icons.check_rounded : Icons.hourglass_top_rounded, 
                          color: status == 'Completed' ? Colors.greenAccent : Colors.orangeAccent, size: 30),
                      ),
                      const SizedBox(height: 15),
                      Text(status, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey)),
                      const SizedBox(height: 10),
                      Text('฿ ${totalMoney.toStringAsFixed(2)}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: kWhiteText)),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                
                Align(alignment: Alignment.centerLeft, child: Text('Items Breakdown', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold))),
                const SizedBox(height: 15),
                
                if (breakdown.isEmpty) const Text('No breakdown details.', style: TextStyle(color: Colors.grey)) else 
                  ...breakdown.map((item) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: kSurfaceColor, borderRadius: BorderRadius.circular(15)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.circle, size: 10, color: kPrimaryColor),
                            const SizedBox(width: 10),
                            Text(item['bottleType'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, color: kWhiteText)),
                          ],
                        ),
                        Text('${item['count']} units', style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )),
                  
                if (status == 'Completed' && data['slipImageUrl'] != null) ...[
                  const SizedBox(height: 25),
                  Align(alignment: Alignment.centerLeft, child: Text('Payment Proof', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 15),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(data['slipImageUrl']),
                  ),
                ]
              ],
            ),
          );
        },
      ),
    );
  }
}