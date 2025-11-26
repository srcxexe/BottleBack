import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// --- Light Theme Constants (ชุดสีสว่าง) ---
const Color kBackgroundColor = Color(0xFFF5F5F5); // พื้นหลังสว่างมาก
const Color kSurfaceColor = Colors.white;          // สี Card, Surface (ขาว)
const Color kPrimaryColor = Color(0xFF00796B);    // สีเขียวเข้ม (Dark Teal)
const Color kBlackText = Colors.black87;           // สีตัวอักษรเข้ม
const Color kGreyText = Colors.black54;            // สีตัวอักษรรอง

class HistoryDetailScreen extends StatelessWidget {
  final String historyId;
  const HistoryDetailScreen({Key? key, required this.historyId}) : super(key: key);

  Future<void> _updateRequestStatus(BuildContext context, String status) async {
    try {
      await FirebaseFirestore.instance.collection('sale_requests').doc(historyId).update({
        'status': status,
        'updateTimestamp': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        // ไม่ pop ออกทันที แต่แสดง SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction status updated to $status.'),
            backgroundColor: kPrimaryColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        // เปลี่ยนสี AppBar เป็นสีพื้นหลัง และใช้สีข้อความเข้ม
        title: const Text('Transaction Details', style: TextStyle(color: kBlackText, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: kBackgroundColor, elevation: 0, centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kBlackText, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('sale_requests').doc(historyId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
             return const Center(child: Text('Request not found.', style: TextStyle(color: kGreyText)));
          }
          
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'Pending';
          final money = (data['totalMoney'] ?? 0.0).toDouble();
          final requestDate = data['timestamp'] != null 
              ? DateFormat('dd MMM yyyy, HH:mm').format((data['timestamp'] as Timestamp).toDate()) : '-';
          
          // ดึงข้อมูล items ออกมาและตรวจสอบชนิดข้อมูลอย่างปลอดภัย
          final List<dynamic>? itemsList = data['items'] as List<dynamic>?;

          Color statusColor;
          switch (status) {
            case 'Completed': statusColor = Colors.green.shade700; break;
            case 'Rejected': statusColor = Colors.red.shade700; break;
            case 'Paid': statusColor = Colors.blue.shade700; break;
            case 'In Progress': statusColor = Colors.purple.shade700; break;
            default: statusColor = kPrimaryColor;
          }

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 120), // เว้นที่สำหรับปุ่มด้านล่าง
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Status Card ---
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(color: kSurfaceColor, borderRadius: BorderRadius.circular(15)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(label: 'Status', value: status, color: statusColor, isBold: true),
                          const Divider(height: 25, color: kBackgroundColor),
                          _buildDetailRow(label: 'Total Received', value: '฿${money.toStringAsFixed(2)}', color: kPrimaryColor, isBold: true, fontSize: 20),
                          _buildDetailRow(label: 'Request Date', value: requestDate, color: kBlackText),
                          _buildDetailRow(label: 'Buyer Name', value: data['buyerName'] ?? 'N/A', color: kBlackText),
                        ],
                      ),
                    ),

                    // --- Item List (Items Breakdown) ---
                    const SizedBox(height: 25),
                    Align(alignment: Alignment.centerLeft, child: Text('Items Breakdown', style: TextStyle(color: kGreyText, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 15),
                    
                    // *** FIX: ใช้ Collection IF แยกกันเพื่อแก้ Syntax Error ***
                    if (itemsList != null && itemsList.isNotEmpty)
                      ...itemsList.map((item) {
                        final itemMap = item as Map<String, dynamic>;
                        return Container(
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
                                  // ใช้ kBlackText
                                  Text(itemMap['bottleType'] ?? 'Unknown Type', style: const TextStyle(fontWeight: FontWeight.w600, color: kBlackText)),
                                ],
                              ),
                              // ใช้ kGreyText
                              Text('${itemMap['count'] ?? '0'} units', style: const TextStyle(color: kGreyText)),
                            ],
                          ),
                        );
                      }).toList(),
                    
                    // *** FIX: Conditional IF สำหรับแสดงข้อความไม่มีรายการ ***
                    if (itemsList == null || itemsList.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Text('No item details found for this request.', style: TextStyle(color: kGreyText)),
                        ),
                      ),
                    // ******************************************************
                    
                    // --- Payment Proof ---
                    if (status == 'Paid' && data['slipImageUrl'] != null) ...[
                      const SizedBox(height: 25),
                      Align(alignment: Alignment.centerLeft, child: Text('Payment Proof', style: TextStyle(color: kGreyText, fontWeight: FontWeight.bold))),
                      const SizedBox(height: 15),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(data['slipImageUrl'], fit: BoxFit.cover),
                      ),
                    ],
                    // เว้นบรรทัดสุดท้าย หากไม่มี Payment Proof
                    if (status != 'Paid' || data['slipImageUrl'] == null) const SizedBox(height: 20),
                  ],
                ),
              ),
              
              // --- Bottom Action Button (Seller: Confirm Complete) ---
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kSurfaceColor,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
                  ),
                  child: status == 'Paid'
                      ? _buildActionButton(
                          label: 'Confirm Payment Received',
                          onPressed: () => _updateRequestStatus(context, 'Completed'),
                          color: Colors.green.shade700, // สีเข้มสำหรับปุ่มหลัก
                          textColor: Colors.white,
                        )
                      : _buildActionButton(
                          label: 'Status: $status',
                          onPressed: null,
                          color: Colors.grey.shade300, // สีเทาอ่อนสำหรับปุ่มที่ไม่ทำงาน
                          textColor: kGreyText, // ใช้สีเข้มเพื่อให้ข้อความเด่นบนพื้นหลังอ่อน
                        ),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailRow({required String label, required String value, required Color color, bool isBold = false, double fontSize = 16}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: kGreyText), // ใช้ kGreyText
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required String label, required VoidCallback? onPressed, required Color color, Color textColor = Colors.white}) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor, // ใช้สีข้อความที่กำหนด
          ),
        ),
      ),
    );
  }
}