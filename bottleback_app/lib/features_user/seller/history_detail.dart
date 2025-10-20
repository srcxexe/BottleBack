import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// --- Constants (อ้างอิงจาก dashboard.dart) ---
const Color kBackgroundColor = Color(0xFFB2F5E6); // *** สีพื้นหลังใหม่ ***
const Color kPrimaryColor = Color(0xFF00BFA5); // *** สีหลักใหม่ ***
const Color kAccentColor = Color(0xFFFFCC80); 

class HistoryDetailScreen extends StatelessWidget {
  final String historyId;

  const HistoryDetailScreen({Key? key, required this.historyId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // *** พื้นหลังของ Scaffold ใช้สีใหม่ ***
      backgroundColor: kBackgroundColor, 
      appBar: AppBar(
        // *** พื้นหลัง AppBar ใช้สีใหม่ ***
        backgroundColor: kBackgroundColor, 
        elevation: 0,
        title: const Text(
          'Sale Detail',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            // ตัวอักษร Title เป็นสีดำ (ตัดกับพื้นหลังใหม่)
            color: Colors.black, 
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios, 
            // ปุ่ม Back เป็นสีดำ (ตัดกับพื้นหลังใหม่)
            color: Colors.black, 
            size: 20
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('sales_history').doc(historyId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;

          if (!snapshot.hasData || data == null) {
            return const Center(child: Text('Sale history not found.'));
          }

          final totalMoney = (data['totalMoney'] ?? 0.0).toDouble();
          final timestamp = data['timestamp'] as Timestamp?;
          double totalWeight = (data['totalWeight'] ?? 0.0).toDouble(); 
          
          final petCount = data['petCount'] ?? 0;
          final petWeight = (data['petWeight'] ?? 0.0).toDouble();
          final hdpeCount = data['hdpeCount'] ?? 0;
          final hdpeWeight = (data['hdpeWeight'] ?? 0.0).toDouble();
          final canCount = data['canCount'] ?? 0;
          final canWeight = (data['canWeight'] ?? 0.0).toDouble();

          if (totalWeight == 0.0 && (petWeight + hdpeWeight + canWeight) > 0) {
             totalWeight = petWeight + hdpeWeight + canWeight;
          }

          String dateString = 'N/A';
          if (timestamp != null) {
            final DateFormat formatter = DateFormat('dd MMM yyyy, HH:mm:ss');
            dateString = formatter.format(timestamp.toDate());
          }

          final totalAllWeight = petWeight + hdpeWeight + canWeight;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card (พื้นหลังยังคงเป็นสีขาวเพื่อเน้น)
                _buildAnimatedHeaderCard(context, totalMoney, totalWeight, dateString, historyId),
                const SizedBox(height: 30),

                // Breakdown Title
                const Text(
                  'Sales Breakdown',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 15),

                // Breakdown Cards (พื้นหลังยังคงเป็นสีขาวเพื่อเน้น)
                _buildModernBreakdownCard(
                  type: 'PET Bottles',
                  count: petCount,
                  weight: petWeight,
                  color: Colors.blue.shade600,
                  icon: Icons.local_drink_rounded,
                  totalAllWeight: totalAllWeight,
                ),
                _buildModernBreakdownCard(
                  type: 'HDPE Bottles',
                  count: hdpeCount,
                  weight: hdpeWeight,
                  color: Colors.green.shade600,
                  icon: Icons.water_drop_rounded,
                  totalAllWeight: totalAllWeight,
                ),
                _buildModernBreakdownCard(
                  type: 'Aluminum Cans',
                  count: canCount,
                  weight: canWeight,
                  color: Colors.orange.shade600,
                  icon: Icons.egg_rounded, 
                  totalAllWeight: totalAllWeight,
                ),

                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Header Card (ใช้สีขาว) ---
  Widget _buildAnimatedHeaderCard(BuildContext context, double money, double weight, String date, String id) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white, // พื้นหลังสีขาว
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), 
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Sale Amount',
                style: TextStyle(fontSize: 18, color: Colors.black54, fontWeight: FontWeight.w500), 
              ),
              Icon(Icons.monetization_on_rounded, color: kPrimaryColor, size: 28), // ไอคอนใช้สีหลักใหม่
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: money),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Text(
                '฿ ${value.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: kPrimaryColor, // ยอดเงินใช้สีหลักใหม่
                ),
              );
            },
          ),
          const Divider(color: Colors.grey, height: 30), 
          _buildElegantDetailRow(
            label: 'Transaction ID',
            value: id,
            icon: Icons.credit_card_rounded,
            color: Colors.black, 
          ),
          _buildElegantDetailRow(
            label: 'Transaction Time',
            value: date,
            icon: Icons.calendar_today_rounded,
            color: Colors.black, 
          ),
          _buildElegantDetailRow(
            label: 'Total Weight',
            value: '${weight.toStringAsFixed(3)} kg',
            icon: Icons.scale_rounded,
            color: Colors.black, 
          ),
        ],
      ),
    );
  }

  Widget _buildElegantDetailRow({required String label, required String value, required IconData icon, required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color.withOpacity(0.6)), 
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: color.withOpacity(0.6), fontSize: 13), 
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color, 
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

  // --- Breakdown Card (ใช้สีขาว) ---
  Widget _buildModernBreakdownCard({
    required String type,
    required int count,
    required double weight,
    required Color color,
    required IconData icon,
    required double totalAllWeight, 
  }) {
    if (count == 0 && weight == 0.0) return const SizedBox.shrink(); 

    double percentage = totalAllWeight > 0 ? (weight / totalAllWeight) : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 30, color: color),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  type,
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: color),
                ),
              ),
              Text(
                '${(percentage * 100).toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color.withOpacity(0.8)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 15),
          _buildBreakdownItem('Units', '$count pcs', Icons.inventory_2_outlined),
          _buildBreakdownItem('Weight', '${weight.toStringAsFixed(3)} kg', Icons.fitness_center_outlined),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.black87, fontSize: 15),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black, fontSize: 15),
          ),
        ],
      ),
    );
  }
}