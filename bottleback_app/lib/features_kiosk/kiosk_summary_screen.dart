import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'kiosk_payment_screen.dart'; 
// import 'kiosk_main_screen.dart'; // สามารถเอาออกได้ถ้าไม่ใช้ KioskItem

// --- Light Theme Constants ---
const Color kBackgroundColor = Color(0xFFF5F5F5); 
const Color kSurfaceColor = Colors.white;          
const Color kPrimaryColor = Color(0xFF80CBC4);    
const Color kBlackText = Colors.black87;           
const Color kGreyText = Colors.black54;            

class KioskSummaryScreen extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final int totalCount;
  final double totalWeight;
  final double totalMoney;
  final String sellerId; // รับ sellerId

  const KioskSummaryScreen({
    super.key,
    required this.items,
    required this.totalCount,
    required this.totalWeight,
    required this.totalMoney,
    required this.sellerId, // กำหนดให้รับ sellerId
  });

  // ฟังก์ชันนำทางไปยังหน้าเลือกวิธีการจ่ายเงิน
  void _navigateToPayment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KioskPaymentScreen(
          totalMoney: totalMoney,
          items: items,
          sellerId: sellerId, // ส่ง sellerId
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Transaction Summary', style: TextStyle(color: kBlackText, fontWeight: FontWeight.bold)),
        backgroundColor: kSurfaceColor, elevation: 0, centerTitle: true,
        iconTheme: const IconThemeData(color: kBlackText),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary Card
            Card(
              color: kSurfaceColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Order Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryColor)),
                    const Divider(color: kGreyText),

                    // รายการสินค้า
                    ...items.map((item) => _buildItemRow(
                      item['bottleType'] as String, 
                      item['count'] as int, 
                      item['subTotal'] as double
                    )).toList(),

                    const Divider(color: kGreyText),
                    _buildSummaryRow('Total Units', '$totalCount units', kBlackText),
                    _buildSummaryRow('Total Weight', '${totalWeight.toStringAsFixed(3)} kg', kBlackText),
                    const SizedBox(height: 10),
                    _buildSummaryRow('Total Payout', '฿${totalMoney.toStringAsFixed(2)}', kPrimaryColor, isBold: true, fontSize: 24),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),

            // Action Button
            _buildActionButton(
              label: 'Proceed to Payment',
              icon: Icons.payment_rounded,
              onPressed: totalMoney > 0 ? () => _navigateToPayment(context) : null,
              color: kPrimaryColor,
            ),

            const SizedBox(height: 15),

            // Cancel Button
            _buildActionButton(
              label: 'Cancel & Add More',
              icon: Icons.edit_note,
              onPressed: () => Navigator.pop(context),
              color: Colors.blueGrey,
            ),

            const SizedBox(height: 15),
            Text(
              'Seller ID: $sellerId',
              style: const TextStyle(fontSize: 12, color: kGreyText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(String type, int count, double money) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$type (${count} units)', style: const TextStyle(color: kBlackText)),
          Text('฿${money.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: kBlackText)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color, {bool isBold = false, double fontSize = 16}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: fontSize, color: isBold ? kBlackText : kGreyText, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.w900 : FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildActionButton({required String label, required IconData icon, required VoidCallback? onPressed, required Color color}) {
    return SizedBox(
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 24),
        label: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 5,
        ),
      ),
    );
  }
}