import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
// ต้อง import หน้าจอถัดไปสำหรับการโอนเงิน
import 'transfer_detail_screen.dart'; 

// --- Constants ---
const Color kBackgroundColor = Color(0xFFB2F5E6); 
const Color kPrimaryColor = Color(0xFF00BFA5); 
const Color kDarkTextColor = Colors.black87;

class RequestDetailScreen extends StatelessWidget {
  final String requestId;

  const RequestDetailScreen({Key? key, required this.requestId}) : super(key: key);

  // ดึงข้อมูลคำร้อง
  Future<Map<String, dynamic>?> _fetchRequestData(String id) async {
    final requestDoc = await FirebaseFirestore.instance.collection('sale_requests').doc(id).get();
    if (!requestDoc.exists) return null;

    final requestData = requestDoc.data()!;
    return {'request': requestData, 'requestId': id};
  }

  // อัปเดตสถานะใน Firestore
  Future<void> _updateRequestStatus(BuildContext context, String status) async {
    try {
      await FirebaseFirestore.instance.collection('sale_requests').doc(requestId).update({
        'status': status,
        'updateTimestamp': FieldValue.serverTimestamp(), // เก็บเวลาที่อัปเดต
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request status updated to $status.'),
            backgroundColor: status == 'Rejected' ? Colors.red : Colors.green,
          ),
        );
        // Pop กลับไปหน้ารายการ (ถ้าสถานะไม่ใช่ In Progress)
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

  // Widget สำหรับแสดงข้อมูลแต่ละรายการ
  Widget _buildInfoRow({required String label, required String value, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: kPrimaryColor.withOpacity(0.8)), 
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.black54, fontSize: 13), 
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: kDarkTextColor, 
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Widget ปุ่ม Action
  Widget _buildActionButton({required String label, required VoidCallback? onPressed, required Color color}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
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
        title: const Text('Sale Request Detail', style: TextStyle(color: kDarkTextColor, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchRequestData(requestId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Error loading request data.'));
          }

          final requestData = snapshot.data!['request'] as Map<String, dynamic>;
          
          final money = (requestData['totalMoney'] ?? 0.0).toDouble();
          final totalWeight = (requestData['totalWeight'] ?? 0.0).toDouble();
          final status = requestData['status'] as String? ?? 'Unknown';
          final sellerId = requestData['sellerId'] as String;
          final timestamp = requestData['timestamp'] as Timestamp?;
          final date = timestamp != null
              ? DateFormat('dd MMMM yyyy, HH:mm').format(timestamp.toDate())
              : 'N/A';
          
          // ข้อมูลผู้ขายที่ถูกบันทึกใน request (จาก dashboard.dart)
          final sellerName = requestData['sellerName'] ?? 'N/A';
          final sellerPhone = requestData['sellerPhone'] ?? 'N/A';
          final sellerBank = requestData['sellerBank'] ?? 'N/A';
          final sellerBankNo = requestData['sellerBankNo'] ?? 'N/A';

          // --- UI เริ่มต้นที่นี่ ---
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Card
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Amount', style: TextStyle(fontSize: 16, color: Colors.black54)),
                      const SizedBox(height: 5),
                      Text(
                        '฿ ${money.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: kPrimaryColor,
                        ),
                      ),
                      const Divider(height: 20),
                      _buildInfoRow(
                        label: 'Total Weight',
                        value: '${totalWeight.toStringAsFixed(3)} kg',
                        icon: Icons.scale,
                      ),
                      _buildInfoRow(
                        label: 'Request Date',
                        value: date,
                        icon: Icons.calendar_today,
                      ),
                       _buildInfoRow(
                        label: 'Status',
                        value: status,
                        icon: Icons.info_outline,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Seller/Bank Info Card
                const Text('Seller & Bank Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kDarkTextColor)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(label: 'Seller Name', value: sellerName, icon: Icons.person_outline),
                      _buildInfoRow(label: 'Phone Number', value: sellerPhone, icon: Icons.phone_outlined),
                      const Divider(height: 20),
                      _buildInfoRow(label: 'Bank Name', value: sellerBank, icon: Icons.account_balance_outlined),
                      _buildInfoRow(label: 'Account No.', value: sellerBankNo, icon: Icons.credit_card_outlined),
                    ],
                  ),
                ),
                
                const Spacer(),

                // Action Buttons
                if (status == 'Pending')
                  Row(
                    children: [
                      // ปุ่มปฏิเสธ
                      Expanded(
                        child: _buildActionButton(
                          label: 'Reject',
                          onPressed: () => _updateRequestStatus(context, 'Rejected'),
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(width: 15),
                      // ปุ่มยืนยันและดำเนินการโอนเงิน
                      Expanded(
                        child: _buildActionButton(
                          label: 'Transfer',
                          onPressed: () {
                            // 1. เปลี่ยนสถานะเป็น In Progress ก่อน
                            _updateRequestStatus(context, 'In Progress').then((_) {
                              // 2. นำทางไปยังหน้า Transfer Detail
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) => TransferDetailScreen(
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
                    onPressed: null, // ปิดการใช้งานปุ่มหากไม่ใช่สถานะ Pending
                    color: Colors.grey,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}