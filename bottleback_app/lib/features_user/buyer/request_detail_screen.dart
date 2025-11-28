import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'transfer_detail_screen.dart'; 

// --- Light Theme Constants ---
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
        Navigator.pop(context); // กลับไปยังหน้า Request List
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
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text('Request Details', style: TextStyle(color: kBlackText, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kBlackText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchRequestData(requestId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: kPrimaryColor));

          final requestData = snapshot.data!['request'] as Map<String, dynamic>;
          final sellerId = requestData['sellerId'] ?? 'N/A';
          final money = (requestData['totalMoney'] ?? 0.0) as num;
          final status = requestData['status'] ?? 'Pending';
          final items = List<Map<String, dynamic>>.from(requestData['items'] ?? []);
          final timestamp = requestData['timestamp'] as Timestamp?;
          final date = timestamp != null ? DateFormat('dd MMM yyyy, HH:mm').format(timestamp.toDate()) : 'N/A';
          final type = requestData['type'] ?? 'Standard Request';
          final isKiosk = type == 'Kiosk Deposit';

          // คำนวณจำนวนชิ้นรวมและน้ำหนักรวม
          final totalItems = items.fold<int>(0, (sum, item) => sum + (item['count'] as int? ?? 0));
          final totalWeight = items.fold<double>(0.0, (sum, item) => sum + (item['weightKg'] as num? ?? 0.0).toDouble());
          
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
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
                          boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow(label: 'Seller ID', value: sellerId.substring(0, 8).toUpperCase()),
                            _buildDetailRow(label: 'Request Date', value: date),
                            _buildDetailRow(label: 'Status', value: status, color: status == 'Pending' ? Colors.orange.shade700 : (status == 'Completed' || status == 'Paid' ? kPrimaryColor : Colors.blue.shade700)),
                            const Divider(color: Colors.black12, height: 25),
                            _buildDetailRow(label: 'Total Items', value: '$totalItems units'),
                            _buildDetailRow(label: 'Total Weight', value: '${totalWeight.toStringAsFixed(2)} kg'),
                            _buildDetailRow(label: 'Amount Due', value: '฿${money.toStringAsFixed(2)}', color: kPrimaryColor, isBold: true, fontSize: 24),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 25),
                      Text('Item Breakdown', style: TextStyle(color: kGreyText, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),

                      // Items List
                      ...items.map((item) => _buildItemTile(item)),

                      // Kiosk Note (ถ้ามี)
                      if (isKiosk) ...[
                        const SizedBox(height: 20),
                        const Center(child: Text('Note: This is an automatically completed Kiosk Deposit.', style: TextStyle(color: kGreyText))),
                      ]
                    ],
                  ),
                ),
              ),
              
              // Action Buttons (Bottom Bar)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kSurfaceColor,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
                ),
                child: SafeArea(
                  top: false,
                  child: status == 'Pending' && !isKiosk
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
                                _updateRequestStatus(context, 'In Progress').then((_) {
                                  Navigator.push(context, MaterialPageRoute(builder: (ctx) => TransferDetailScreen(
                                        requestId: requestId,
                                        sellerId: sellerId,
                                        amount: money.toDouble(),
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

  Widget _buildDetailRow({required String label, required String value, Color color = kBlackText, bool isBold = false, double fontSize = 16}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: kGreyText)),
          Text(value, style: TextStyle(color: color, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, fontSize: fontSize)),
        ],
      ),
    );
  }

  Widget _buildItemTile(Map<String, dynamic> item) {
    final count = item['count'] ?? 0;
    final weight = (item['weightKg'] ?? 0.0).toDouble();
    final subTotal = (item['subTotal'] ?? 0.0).toDouble();
    final bottleType = item['bottleType'] ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$bottleType ($count units)', style: const TextStyle(fontWeight: FontWeight.bold, color: kBlackText)),
              Text('฿${subTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor)),
            ],
          ),
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('${weight.toStringAsFixed(2)} kg', style: const TextStyle(color: kGreyText, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required String label, required VoidCallback? onPressed, required Color color}) {
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
            color: color == Colors.grey.shade400 ? kBlackText : Colors.white,
          ),
        ),
      ),
    );
  }
}