import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// --- Dark Theme Constants ---
const Color kBackgroundColor = Color(0xFFF5F5F5); // พื้นหลังสว่างมาก (เกือบขาว)
const Color kSurfaceColor = Colors.white;          // สี Card, Nav Bar (ขาว)
const Color kPrimaryColor = Color(0xFF00796B);    // สีเขียวเข้ม (Dark Teal)
const Color kSecondaryColor = Color(0xFF80CBC4);  // สีเขียวอ่อน (Light Teal)
const Color kBlackText = Colors.black87;           // สีตัวอักษรเข้ม
const Color kGreyText = Colors.black54;  
const Color kWhiteText = Colors.black;
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
          final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
          final totalMoney = (data['totalMoney'] ?? 0.0) as num;
          final status = data['status'] ?? 'Pending';
          final type = data['type'] ?? 'Standard Request';
          final timestamp = data['timestamp'] as Timestamp?;
          final date = timestamp != null 
              ? DateFormat('dd MMM yyyy, HH:mm').format(timestamp.toDate()) 
              : 'Unknown Date';

          final isKiosk = type == 'Kiosk Deposit';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kSurfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isKiosk ? Icons.recycling_rounded : Icons.receipt_long_rounded, 
                        size: 50, 
                        color: kPrimaryColor
                      ),
                      const SizedBox(height: 15),
                      Text(isKiosk ? 'Kiosk Deposit' : 'Sale Request', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                      const SizedBox(height: 5),
                      Text('฿${totalMoney.toStringAsFixed(2)}', style: const TextStyle(color: kWhiteText, fontSize: 32, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(
                          color: status == 'Completed' ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(status, style: TextStyle(color: status == 'Completed' ? Colors.greenAccent : Colors.orangeAccent, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 10),
                      _buildDetailRow('Date', date, kWhiteText),
                      _buildDetailRow('Transaction ID', historyId.substring(0, 8).toUpperCase(), Colors.grey),
                      if (isKiosk)
                        _buildDetailRow('Channel', 'Kiosk Machine (Wallet)', kPrimaryColor),
                    ],
                  ),
                ),
                
                const SizedBox(height: 25),
                Text('Items Recycled Details', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),

                // Items List (UPDATED to show Weight and Price)
                ...items.map((item) {
                    final count = item['count'] ?? 0;
                    final weight = (item['weightKg'] ?? 0.0).toDouble(); // ดึงน้ำหนัก (ถ้ามี)
                    final subTotal = (item['subTotal'] ?? 0.0).toDouble(); // ดึงราคา (ถ้ามี)
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(color: kSurfaceColor, borderRadius: BorderRadius.circular(15)),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.circle, size: 10, color: kPrimaryColor),
                                  const SizedBox(width: 10),
                                  Text(item['bottleType'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, color: kWhiteText, fontSize: 16)),
                                ],
                              ),
                              Text('$count units', style: const TextStyle(color: kWhiteText, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          // แสดงรายละเอียดเพิ่มเติม (น้ำหนัก และ ราคา) เฉพาะเมื่อมีข้อมูล
                          if (weight > 0 || subTotal > 0) ...[
                             const SizedBox(height: 10),
                             const Divider(color: Colors.white10, height: 1),
                             const SizedBox(height: 10),
                             Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                  if (weight > 0)
                                    Row(
                                      children: [
                                        const Icon(Icons.scale, size: 14, color: Colors.grey),
                                        const SizedBox(width: 5),
                                        Text('${weight.toStringAsFixed(2)} kg', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                      ],
                                    )
                                  else const SizedBox(), // Spacer
                                  
                                  if (subTotal > 0)
                                    Text('฿${subTotal.toStringAsFixed(2)}', style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 15)),
                               ],
                             )
                          ]
                        ],
                      ),
                    );
                }),
                  
                if (status == 'Completed' && data['slipImageUrl'] != null && !isKiosk) ...[
                  const SizedBox(height: 25),
                  Align(alignment: Alignment.centerLeft, child: Text('Payment Proof', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 15),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(data['slipImageUrl']),
                  ),
                ],

                if (isKiosk) ...[
                   const SizedBox(height: 25),
                   Center(
                     child: Text(
                       'This transaction was automatically processed by the Kiosk.',
                       style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                       textAlign: TextAlign.center,
                     ),
                   ),
                ]
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}