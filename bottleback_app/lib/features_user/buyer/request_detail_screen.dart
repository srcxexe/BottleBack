import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'transfer_detail_screen.dart';

// --- Constants ---
const Color kBackgroundColor = Color(0xFFB2F5E6); 
const Color kPrimaryColor = Color(0xFF00BFA5); 
const Color kDarkTextColor = Colors.black87;

class RequestDetailScreen extends StatelessWidget {
  final String requestId;

  const RequestDetailScreen({Key? key, required this.requestId}) : super(key: key);

  // ดึงข้อมูลคำร้องและข้อมูล Seller
  Future<Map<String, dynamic>?> _fetchRequestAndSellerData(String id) async {
    final requestDoc = await FirebaseFirestore.instance.collection('sale_requests').doc(id).get();
    if (!requestDoc.exists) return null;

    final requestData = requestDoc.data()!;
    final sellerId = requestData['sellerId'] as String;

    // ดึงข้อมูลผู้ขาย (seller)
    final sellerDoc = await FirebaseFirestore.instance.collection('sellers').doc(sellerId).get();
    
    return {
      'request': requestData,
      'seller': sellerDoc.exists ? sellerDoc.data() : null,
      'requestId': id,
      'sellerId': sellerId,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text('Request Details', style: TextStyle(color: kDarkTextColor, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchRequestAndSellerData(requestId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Error loading request or seller data.'));
          }

          final data = snapshot.data!;
          final request = data['request'] as Map<String, dynamic>;
          final seller = data['seller'] as Map<String, dynamic>?;

          // ... (ดึงข้อมูล) ...
          final totalMoney = (request['totalMoney'] ?? 0.0).toDouble();
          final totalWeight = (request['totalWeight'] ?? 0.0).toDouble();
          final timestamp = request['timestamp'] as Timestamp?;
          final status = request['status'] ?? 'Pending'; // Pending, Paid, Completed
          
          final dateString = timestamp != null 
              ? DateFormat('dd MMM yyyy, HH:mm:ss').format(timestamp.toDate()) 
              : 'N/A';
          
          final sellerName = seller?['name'] ?? 'N/A';
          final sellerPhone = seller?['phone'] ?? 'N/A';
          // สมมติว่าต้องการแสดงแค่ชื่อธนาคาร หากต้องการเลขบัญชี ให้ใช้ seller?['bankNo']
          final sellerBank = seller?['bank'] ?? 'N/A'; 

          // ตรวจสอบและแสดงปุ่มตามสถานะ
          Widget actionButton;
          if (status == 'Pending') {
            actionButton = _buildActionButton(
              label: 'Proceed to Payment',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TransferDetailScreen(
                      requestId: requestId,
                      sellerId: data['sellerId'],
                      amount: totalMoney,
                    ),
                  ),
                );
              },
              color: kPrimaryColor,
            );
          } else if (status == 'Paid') {
            // สถานะ Paid: แสดงปุ่มที่ไม่สามารถกดได้
            actionButton = _buildActionButton(
              label: 'Payment Completed (Waiting for Seller to Confirm)',
              onPressed: null,
              color: Colors.green.shade700,
            );
          } else if (status == 'Completed') {
            // สถานะ Completed: แสดงปุ่มที่ไม่สามารถกดได้
            actionButton = _buildActionButton(
              label: 'Transaction Completed',
              onPressed: null,
              color: Colors.blueGrey.shade700,
            );
          } else {
             actionButton = const SizedBox.shrink();
          }

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(totalMoney, totalWeight, status),
                    const SizedBox(height: 30),

                    // --- Seller Information ---
                    const Text('Seller Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kDarkTextColor)),
                    const SizedBox(height: 10),
                    _buildDetailCard(
                      children: [
                        _buildDetailRow(label: 'Name', value: sellerName, icon: Icons.person_rounded),
                        _buildDetailRow(label: 'Phone', value: sellerPhone, icon: Icons.phone_rounded),
                        _buildDetailRow(label: 'Bank (Display only)', value: sellerBank, icon: Icons.account_balance_rounded),
                      ]
                    ),
                    const SizedBox(height: 20),

                    // --- Request Details ---
                    const Text('Order Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kDarkTextColor)),
                    const SizedBox(height: 10),
                    _buildDetailCard(
                      children: [
                        _buildDetailRow(label: 'Request ID', value: data['requestId'], icon: Icons.credit_card_rounded),
                        _buildDetailRow(label: 'Date & Time', value: dateString, icon: Icons.calendar_today_rounded),
                        _buildDetailRow(label: 'Total Weight', value: '${totalWeight.toStringAsFixed(3)} kg', icon: Icons.scale_rounded),
                      ]
                    ),
                    const SizedBox(height: 100), // Padding สำหรับปุ่มด้านล่าง
                  ],
                ),
              ),
              
              // *** Floating Action Button ***
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: actionButton,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Widget สรุปยอดเงิน
  Widget _buildSummaryCard(double money, double weight, String status) {
    Color statusColor;
    if (status == 'Pending') {
      statusColor = kPrimaryColor;
    } else if (status == 'Paid') {
      statusColor = Colors.green.shade700;
    } else {
      statusColor = Colors.blueGrey.shade700;
    }
    
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Amount to Pay',
            style: TextStyle(fontSize: 18, color: Colors.black54, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 5),
          Text(
            '฿ ${money.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: statusColor,
            ),
          ),
          const Divider(color: Colors.grey, height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSmallDetail(Icons.info_outline, 'Status', status, statusColor),
              _buildSmallDetail(Icons.scale, 'Weight', '${weight.toStringAsFixed(2)} kg', kDarkTextColor),
            ],
          )
        ],
      ),
    );
  }
  
  // Widget รายละเอียดเล็กๆ ใน Summary Card
  Widget _buildSmallDetail(IconData icon, String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }


  // Widget Card สำหรับรายละเอียด
  Widget _buildDetailCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(children: children),
    );
  }
  
  // Widget แถวแสดงรายละเอียด
  Widget _buildDetailRow({required String label, required String value, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          // แก้ไข: ใช้ foregroundColor เพื่อกำหนดสีข้อความเมื่อปุ่มถูก disabled
          foregroundColor: onPressed == null ? Colors.white.withOpacity(0.7) : Colors.white,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}