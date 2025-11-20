import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'transfer_detail_screen.dart'; 

// --- Dark Theme Constants ---
const Color kBackgroundColor = Color(0xFF121212);
const Color kSurfaceColor = Color(0xFF1E1E1E);
const Color kPrimaryColor = Color(0xFF00BFA5);
const Color kWhiteText = Colors.white;

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
            backgroundColor: status == 'Rejected' ? Colors.red : kPrimaryColor,
          ),
        );
        if (status == 'Rejected') {
           Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildInfoRow({required String label, required String value, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: kPrimaryColor), 
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: kWhiteText, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton({required String label, required VoidCallback? onPressed, required Color color}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text('Sale Request Detail', style: TextStyle(color: kWhiteText, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kWhiteText, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchRequestData(requestId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) return const Center(child: Text('Error loading request data.', style: TextStyle(color: Colors.grey)));

          final requestData = snapshot.data!['request'] as Map<String, dynamic>;
          final money = (requestData['totalMoney'] ?? 0.0).toDouble();
          final totalWeight = (requestData['totalWeight'] ?? 0.0).toDouble();
          final status = requestData['status'] as String? ?? 'Unknown';
          final sellerId = requestData['sellerId'] as String;
          final timestamp = requestData['timestamp'] as Timestamp?;
          final date = timestamp != null ? DateFormat('dd MMMM yyyy, HH:mm').format(timestamp.toDate()) : 'N/A';
          
          final sellerName = requestData['sellerName'] ?? 'N/A';
          final sellerPhone = requestData['sellerPhone'] ?? 'N/A';
          final sellerBank = requestData['sellerBank'] ?? 'N/A';
          final sellerBankNo = requestData['sellerBankNo'] ?? 'N/A';

          // --- ใช้ Column + Expanded เพื่อให้ส่วนเนื้อหาเลื่อนได้ ส่วนปุ่มอยู่ด้านล่าง ---
          return Column(
            children: [
              // 1. ส่วนเนื้อหาที่เลื่อนได้ (Scrollable Content)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: kSurfaceColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Amount', style: TextStyle(fontSize: 16, color: Colors.grey)),
                            const SizedBox(height: 5),
                            Text(
                              '฿ ${money.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: kPrimaryColor),
                            ),
                            const Divider(height: 30, color: Colors.grey),
                            _buildInfoRow(label: 'Total Weight', value: '${totalWeight.toStringAsFixed(3)} kg', icon: Icons.scale),
                            _buildInfoRow(label: 'Request Date', value: date, icon: Icons.calendar_today),
                             _buildInfoRow(label: 'Status', value: status, icon: Icons.info_outline),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),

                      const Text('Seller & Bank Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kWhiteText)),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: kSurfaceColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(label: 'Seller Name', value: sellerName, icon: Icons.person_outline),
                            _buildInfoRow(label: 'Phone Number', value: sellerPhone, icon: Icons.phone_outlined),
                            const Divider(height: 20, color: Colors.grey),
                            _buildInfoRow(label: 'Bank Name', value: sellerBank, icon: Icons.account_balance_outlined),
                            _buildInfoRow(label: 'Account No.', value: sellerBankNo, icon: Icons.credit_card_outlined),
                          ],
                        ),
                      ),
                      
                      // เพิ่มพื้นที่ว่างด้านล่างเพื่อให้แน่ใจว่าเนื้อหาไม่ติดขอบปุ่ม
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // 2. ส่วนปุ่มกด (Sticky Bottom Buttons)
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: kBackgroundColor,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -5)),
                  ],
                ),
                child: Column(
                  children: [
                    if (status == 'Pending')
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              label: 'Reject',
                              onPressed: () => _updateRequestStatus(context, 'Rejected'),
                              color: Colors.red.shade900,
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
                    else
                      _buildActionButton(
                        label: 'Status: $status',
                        onPressed: null, 
                        color: Colors.grey.shade800,
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}