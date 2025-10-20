import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// --- Constants (อ้างอิงจาก dashboard.dart) ---\r\n
const Color kBackgroundColor = Color(0xFFB2F5E6); 
const Color kPrimaryColor = Color(0xFF00BFA5); 
const Color kDarkTextColor = Colors.black87;
const Color kAccentColor = Color(0xFFFFCC80); 

class HistoryDetailScreen extends StatelessWidget {
  final String historyId;

  const HistoryDetailScreen({Key? key, required this.historyId}) : super(key: key);

  // --------------------------------------------------
  // 1. Helper Functions สำหรับสถานะและสี
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
  
  String _getThaiStatus(String status) {
    switch (status) {
      case 'Completed':
        return 'ขายสำเร็จ';
      case 'Rejected':
        return 'ถูกปฏิเสธ';
      case 'In Progress':
        return 'กำลังดำเนินการโอนเงิน';
      case 'Pending':
      default:
        return 'รอการยืนยัน';
    }
  }

  // --------------------------------------------------
  // 2. Widget แสดงรายละเอียดรวม
  // --------------------------------------------------

  Widget _buildInfoRow({required String label, required String value, required IconData icon, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? kPrimaryColor.withOpacity(0.8)), 
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54, fontSize: 15), 
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color ?? kDarkTextColor, 
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // 3. Widget แสดงรายละเอียดการแยกประเภทขวด (Breakdown)
  // --------------------------------------------------
  Widget _buildBreakdownCard({
    required String name,
    required int count,
    required double weight,
    required double money,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ชื่อขวดและยอดเงิน
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  '+ ฿ ${money.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: kDarkTextColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 20, color: Colors.black12),
            // รายละเอียดจำนวนและน้ำหนัก
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoRow(
                  label: 'Units',
                  value: '$count pcs',
                  icon: Icons.inventory_2_outlined,
                  color: Colors.grey.shade600,
                ),
                _buildInfoRow(
                  label: 'Weight',
                  value: '${weight.toStringAsFixed(3)} kg',
                  icon: Icons.fitness_center_outlined,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // 4. Main Build Method
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor, 
      appBar: AppBar(
        backgroundColor: kBackgroundColor, 
        elevation: 0,
        title: const Text(
          'Sale Detail',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: kDarkTextColor, 
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kDarkTextColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('sale_requests').doc(historyId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('ไม่พบรายละเอียดคำร้องขายนี้'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          
          final totalMoney = (data['totalMoney'] ?? 0.0).toDouble();
          final totalWeight = (data['totalWeight'] ?? 0.0).toDouble();
          final timestamp = data['timestamp'] as Timestamp?;
          final status = data['status'] as String? ?? 'Unknown';

          // *** ส่วนที่แก้ไข: การดึงข้อมูล breakdown ให้ยืดหยุ่น ***
          final List<dynamic>? breakdownData = data['breakdown'];
          final List<Map<String, dynamic>> validBreakdown = 
              breakdownData?.whereType<Map<String, dynamic>>().toList() ?? [];
          
          final date = timestamp != null
              ? DateFormat('dd MMMM yyyy, HH:mm').format(timestamp.toDate())
              : 'N/A';
          
          final statusColor = _getStatusColor(status);
          final statusText = _getThaiStatus(status);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Summary Card (ยอดรวมและสถานะ)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ยอดเงินรวม
                      const Text('Total Revenue', style: TextStyle(fontSize: 16, color: Colors.black54)),
                      const SizedBox(height: 5),
                      Text(
                        '฿ ${totalMoney.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: kPrimaryColor,
                        ),
                      ),
                      const Divider(height: 20),
                      
                      // สถานะ
                      _buildInfoRow(
                        label: 'Status',
                        value: statusText,
                        icon: Icons.info_outline,
                        color: statusColor,
                      ),
                      // วันที่
                      _buildInfoRow(
                        label: 'Date/Time',
                        value: date,
                        icon: Icons.calendar_today_outlined,
                      ),
                      // น้ำหนักรวม
                      _buildInfoRow(
                        label: 'Total Weight',
                        value: '${totalWeight.toStringAsFixed(3)} kg',
                        icon: Icons.scale_outlined,
                      ),
                      // รหัสคำร้อง
                      _buildInfoRow(
                        label: 'Request ID',
                        value: historyId,
                        icon: Icons.numbers,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 25),
                
                // 2. Breakdown Section (รายละเอียดขวด)
                const Text(
                  'Bottle Breakdown',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kDarkTextColor),
                ),
                const SizedBox(height: 10),

                if (validBreakdown.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(15.0),
                      child: Text('ไม่พบรายละเอียดการแยกประเภทขวด'),
                    ),
                  )
                else
                  ...validBreakdown.map((item) {
                    return _buildBreakdownCard(
                      name: item['bottleType'] ?? 'Unknown Type',
                      count: (item['count'] ?? 0) as int,
                      weight: (item['weight'] as num? ?? 0.0).toDouble(), 
                      money: (item['money'] as num? ?? 0.0).toDouble(),
                      color: kPrimaryColor, 
                    );
                  }).toList(),

                // 3. แสดงสลิป (ถ้ามีและสถานะเป็น Completed)
                if (status == 'Completed' && data['slipImageUrl'] != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 25),
                      const Text(
                        'Payment Slip',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kDarkTextColor),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          data['slipImageUrl'] as String,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey.shade300,
                              alignment: Alignment.center,
                              child: const Text('Slip image not found or failed to load.'),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}