import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 
import 'history_detail.dart'; // ต้อง import หน้า Detail

// --- Constants (อ้างอิงจาก dashboard.dart) ---\r\n
const Color kBackgroundColor = Color(0xFFB2F5E6); 
const Color kPrimaryColor = Color(0xFF00BFA5); 
const Color kDarkTextColor = Colors.black87;

class SalesHistoryScreen extends StatelessWidget {
  const SalesHistoryScreen({Key? key}) : super(key: key);

  // --------------------------------------------------
  // 1. Helper Functions สำหรับสถานะ
  // --------------------------------------------------

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green.shade600; 
      case 'Rejected':
        return Colors.red.shade600; 
      case 'In Progress':
        return Colors.orange.shade700;
      case 'Pending':
      default:
        return Colors.blue.shade600; 
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Completed':
        return Icons.check_circle_outline;
      case 'Rejected':
        return Icons.cancel_outlined;
      case 'In Progress':
        return Icons.credit_card_outlined;
      case 'Pending':
      default:
        return Icons.hourglass_top_outlined;
    }
  }

  String _getThaiStatus(String status) {
    switch (status) {
      case 'Completed':
        return 'ขายสำเร็จ';
      case 'Rejected':
        return 'ถูกปฏิเสธ';
      case 'In Progress':
        return 'อยู่ระหว่างโอน';
      case 'Pending':
      default:
        return 'รอการยืนยัน';
    }
  }
  
  // --------------------------------------------------
  // 2. Widget Card แสดงรายการประวัติ
  // --------------------------------------------------
  Widget _buildSaleHistoryCard(
    BuildContext context, {
    required String requestId,
    required double money,
    required Timestamp? timestamp,
    required String status,
  }) {
    final date = timestamp != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(timestamp.toDate())
        : 'N/A';
    
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final statusText = _getThaiStatus(status);

    return GestureDetector(
      onTap: () {
        // นำทางไปยังหน้าดูรายละเอียดประวัติการขาย
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HistoryDetailScreen(historyId: requestId),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // ไอคอนสถานะ
                  Icon(statusIcon, color: statusColor, size: 30),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ข้อความสถานะ (ภาษาไทย)
                      Text(
                        statusText, 
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: statusColor, 
                        ),
                      ),
                      const SizedBox(height: 4),
                      // วันที่/เวลา
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // ยอดเงินที่ขายได้
              Row(
                children: [
                  Text(
                    '+ ฿ ${money.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: status == 'Rejected' ? Colors.red.shade600 : statusColor, 
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // 3. Main Build Method
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor, 
        elevation: 0,
        title: const Text(
          'Sales History',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: kDarkTextColor,
          ),
        ),
        automaticallyImplyLeading: false, 
      ),
      body: user == null
          ? const Center(child: Text('กรุณาเข้าสู่ระบบเพื่อดูประวัติการขาย'))
          : StreamBuilder<QuerySnapshot>(
              // ดึงข้อมูลคำร้องขายของผู้ขายคนนี้เท่านั้น
              stream: FirebaseFirestore.instance
                  .collection('sale_requests')
                  .where('sellerId', isEqualTo: user.uid) 
                  .orderBy('timestamp', descending: true) 
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
                }
                if (snapshot.hasError) {
                  // **สำคัญ: ถ้ามี error "requires an index" ต้องไปสร้าง Index ใน Firebase Console**
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('ไม่พบประวัติคำร้องขาย'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    final money = (data['totalMoney'] ?? 0.0).toDouble();
                    final timestamp = data['timestamp'] as Timestamp?;
                    final status = data['status'] as String? ?? 'Pending'; 

                    return _buildSaleHistoryCard(
                      context,
                      requestId: doc.id,
                      money: money,
                      timestamp: timestamp,
                      status: status, 
                    );
                  },
                );
              },
            ),
    );
  }
}