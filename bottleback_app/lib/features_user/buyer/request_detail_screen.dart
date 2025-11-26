import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'transfer_detail_screen.dart'; // <<< ต้องมีไฟล์นี้อยู่

// --- Light Theme Constants (ตามที่กำหนดในไฟล์ของคุณ) ---
const Color kBackgroundColor = Color(0xFFF5F5F5); 
const Color kSurfaceColor = Colors.white;          
const Color kPrimaryColor = Color(0xFF00796B);    
const Color kBlackText = Colors.black87;           
const Color kGreyText = Colors.black54; 

class RequestDetailScreen extends StatelessWidget {
  final String requestId;

  const RequestDetailScreen({Key? key, required this.requestId}) : super(key: key);

  Future<Map<String, dynamic>?> _fetchRequestData(String id) async {
    final requestDoc = await FirebaseFirestore.instance.collection('sale_requests').doc(id).get();
    if (!requestDoc.exists) return null;
    final requestData = requestDoc.data()!;
    return {'request': requestData, 'requestId': id};
  }

  Future<void> _updateRequestStatus(BuildContext context, String status) async {
    try {
      await FirebaseFirestore.instance.collection('sale_requests').doc(requestId).update({
        'status': status,
        'updateTimestamp': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request status updated to $status.'),
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
        title: const Text('Request Details', style: TextStyle(color: kBlackText, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: kBackgroundColor, elevation: 0, centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kBlackText, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchRequestData(requestId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
          
          final data = snapshot.data!['request'] as Map<String, dynamic>;
          final status = data['status'] ?? 'Pending';
          final money = (data['totalMoney'] ?? 0.0).toDouble();
          final sellerId = data['sellerId'] ?? '';
          final requestDate = data['timestamp'] != null 
              ? DateFormat('dd MMM yyyy, HH:mm').format((data['timestamp'] as Timestamp).toDate()) : '-';
          
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
                          _buildDetailRow(label: 'Total Amount', value: '฿${money.toStringAsFixed(2)}', color: kPrimaryColor, isBold: true, fontSize: 20),
                          _buildDetailRow(label: 'Total Weight', value: '${(data['totalWeight'] ?? 0.0).toStringAsFixed(3)} kg', color: kBlackText),
                          _buildDetailRow(label: 'Request Date', value: requestDate, color: kGreyText),
                          _buildDetailRow(label: 'Seller Name', value: data['sellerName'] ?? 'N/A', color: kBlackText),
                        ],
                      ),
                    ),

                    // --- Item List ---
                    const SizedBox(height: 25),
                    Align(alignment: Alignment.centerLeft, child: Text('Items Breakdown', style: TextStyle(color: kGreyText, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 15),
                    
                    if (data['items'] is List)
                      ...((data['items'] as List).map((item) => Container(
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
                                Text(item['bottleType'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, color: kBlackText)),
                              ],
                            ),
                            Text('${item['count']} units', style: const TextStyle(color: kGreyText)),
                          ],
                        ),
                      ))),
                    
                    // --- Payment Proof ---
                    if (status == 'Completed' && data['slipImageUrl'] != null) ...[
                      const SizedBox(height: 25),
                      Align(alignment: Alignment.centerLeft, child: Text('Payment Proof', style: TextStyle(color: kGreyText, fontWeight: FontWeight.bold))),
                      const SizedBox(height: 15),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(data['slipImageUrl'], fit: BoxFit.cover),
                      ),
                    ]
                  ],
                ),
              ),

              // --- Bottom Action Buttons ---
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kSurfaceColor,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                  ),
                  child: status == 'Pending' 
                    ? Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              label: 'Reject',
                              onPressed: () => _updateRequestStatus(context, 'Rejected'),
                              color: Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildActionButton(
                              label: 'Transfer',
                              onPressed: () {
                                // 1. อัปเดตสถานะเป็น In Progress ก่อน
                                _updateRequestStatus(context, 'In Progress').then((_) {
                                  // 2. นำทางไปหน้า Transfer
                                  Navigator.push(context, MaterialPageRoute(builder: (ctx) => TransferDetailScreen(
                                        requestId: requestId,
                                        sellerId: sellerId,
                                        amount: money,
                                      ),
                                    ),
                                  );
                                });
                              },
                              color: kPrimaryColor,
                            ),
                          ),
                        ],
                      )
                    : _buildActionButton(
                        label: 'Status: $status',
                        onPressed: null, 
                        color: Colors.grey.shade400, // Light grey for non-actionable status
                      ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildDetailRow({required String label, required String value, required Color color, bool isBold = false, double fontSize = 16}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: kGreyText),
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

  Widget _buildActionButton({required String label, required VoidCallback? onPressed, required Color color}) {
    return SizedBox(
      height: 50,
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
            color: color == kPrimaryColor ? Colors.white : Colors.black, // ใช้สีขาวสำหรับปุ่มหลัก, สีดำสำหรับปุ่มแดง
          ),
        ),
      ),
    );
  }
}