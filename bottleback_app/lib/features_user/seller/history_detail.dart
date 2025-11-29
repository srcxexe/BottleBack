import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// --- Light Theme Constants ---
const Color kBackgroundColor = Color(0xFFF5F5F5); 
const Color kSurfaceColor = Colors.white;          
const Color kPrimaryColor = Color(0xFF00796B);    
const Color kBlackText = Colors.black87;           
const Color kGreyText = Colors.black54; 

class HistoryDetailScreen extends StatelessWidget {
  final String historyId;
  const HistoryDetailScreen({Key? key, required this.historyId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Transaction Details', style: TextStyle(color: kBlackText, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: kBackgroundColor, 
        elevation: 0, 
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kBlackText, size: 20), 
          onPressed: () => Navigator.pop(context)
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('sale_requests').doc(historyId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
          
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final items = (data['items'] as List<dynamic>? ?? []);
          
          // Filter items
          final validItems = items.where((item) {
             final count = item['count'];
             if (count == null) return false;
             if (count is num && count > 0) return true;
             return false;
          }).toList();

          final status = data['status'] ?? 'Pending';
          final type = data['type'] ?? 'Online Sale'; // ดึงประเภทรายการ (ถ้าไม่มีให้เป็น Online Sale)
          final date = data['timestamp'] != null 
              ? DateFormat('dd MMM yyyy, HH:mm').format((data['timestamp'] as Timestamp).toDate())
              : '-';
          final totalMoney = data['money'] ?? 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Header Section (Total Money Only) ---
                Center(
                  child: Column(
                    children: [
                      const Text('Total Received', style: TextStyle(color: kGreyText)),
                      const SizedBox(height: 5),
                      Text('฿${totalMoney.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: kPrimaryColor)),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // --- NEW SECTION: Transaction Info (Status, Type, Date) ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kSurfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('Status', status, color: _getStatusColor(status), isBold: true),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                      _buildDetailRow('Type', type, color: kBlackText),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                      _buildDetailRow('Date', date, color: kBlackText),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // --- Item Breakdown ---
                if (validItems.isNotEmpty) ...[
                  const Text('Items Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBlackText)),
                  const SizedBox(height: 15),
                  
                  ...validItems.map((item) {
                    final String type = item['bottleType'] ?? 'Unknown';
                    final int count = item['count'] ?? 0;
                    final double? weight = item['weight']; 
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(color: kSurfaceColor, borderRadius: BorderRadius.circular(15)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(_getIconForType(type), size: 24, color: _getColorForType(type)),
                              const SizedBox(width: 15),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(type, style: const TextStyle(fontWeight: FontWeight.w600, color: kBlackText, fontSize: 16)),
                                  if (weight != null && weight > 0)
                                    Text('${weight.toStringAsFixed(2)} kg', style: const TextStyle(fontSize: 12, color: kGreyText)),
                                ],
                              ),
                            ],
                          ),
                          Text('$count units', style: const TextStyle(color: kGreyText, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }).toList(),
                ] else ...[
                   const Center(child: Text('No items to display', style: TextStyle(color: kGreyText))),
                ],

                // --- Payment Proof ---
                if (data['slipImageUrl'] != null) ...[
                  const SizedBox(height: 25),
                  const Text('Payment Proof', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBlackText)),
                  const SizedBox(height: 15),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(data['slipImageUrl']),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper Widget สำหรับสร้างแถวข้อมูล
  Widget _buildDetailRow(String label, String value, {Color? color, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, color: kGreyText)),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color ?? kBlackText,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'Completed' || status == 'Paid') return Colors.green;
    if (status == 'Pending') return Colors.orange;
    if (status == 'Rejected') return Colors.red;
    return kPrimaryColor;
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'PET': return Icons.local_drink_rounded;
      case 'HDPE': return Icons.cleaning_services_rounded;
      case 'CAN': return Icons.sports_bar_rounded;
      case 'GLASS': return Icons.wine_bar_rounded;
      default: return Icons.recycling_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'PET': return Colors.orange;
      case 'HDPE': return Colors.blue;
      case 'CAN': return Colors.green;
      case 'GLASS': return Colors.brown;
      default: return kGreyText;
    }
  }
}