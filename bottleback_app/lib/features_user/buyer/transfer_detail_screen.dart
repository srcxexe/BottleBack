import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'upload_slip_screen.dart'; // <<< ต้องมีไฟล์นี้อยู่

// --- Light Theme Constants (ตามที่คุณใช้งาน) ---
const Color kBackgroundColor = Color(0xFFF5F5F5); 
const Color kSurfaceColor = Colors.white;          
const Color kPrimaryColor = Color(0xFF00796B);    
const Color kBlackText = Colors.black87;           
const Color kGreyText = Colors.black54; 

class TransferDetailScreen extends StatelessWidget {
  final String requestId;
  final String sellerId;
  final double amount;

  const TransferDetailScreen({
    Key? key,
    required this.requestId,
    required this.sellerId,
    required this.amount,
  }) : super(key: key);

  // *** ฟังก์ชันที่ใช้ดึงข้อมูลธนาคารของผู้ขาย ***
  Future<Map<String, dynamic>?> _fetchSellerBankData() async {
    // FIX: โค้ดนี้จะทำงานได้ต่อเมื่อ Security Rules อนุญาต
    final doc = await FirebaseFirestore.instance.collection('sellers').doc(sellerId).get();
    return doc.exists ? doc.data() : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text('Transfer Details', style: TextStyle(color: kBlackText, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kBlackText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchSellerBankData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          final bankData = snapshot.data;

          if (bankData == null) {
            return const Center(child: Text('Seller bank information not found.', style: TextStyle(color: kGreyText)));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Transfer Amount
                _buildAmountDisplay(amount),
                const SizedBox(height: 25),

                // Seller Bank Details
                Text('Seller Bank Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBlackText)),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: kSurfaceColor, borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    children: [
                      _buildDetailRow(icon: Icons.person_rounded, label: 'Account Name', value: bankData['name'] ?? 'N/A'),
                      const Divider(color: kBackgroundColor),
                      _buildDetailRow(icon: Icons.account_balance_rounded, label: 'Bank Name', value: bankData['bank'] ?? 'N/A'),
                      const Divider(color: kBackgroundColor),
                      _buildDetailRow(icon: Icons.credit_card_rounded, label: 'Account No.', value: bankData['bankNo'] ?? 'N/A'),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // Transfer Steps
                Text('Steps to Complete Transfer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBlackText)),
                _buildStep(1, 'Transfer the exact amount (฿ ${amount.toStringAsFixed(2)}) to the bank account above.'),
                _buildStep(2, 'Get the payment slip (screenshot or digital receipt).'),
                _buildStep(3, 'Click "Upload Slip" below to submit the payment proof.'),
                const SizedBox(height: 40),

                // Action Button
                _buildActionButton(
                  label: 'Upload Slip',
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        // นำทางไปหน้าจอถัดไป
                        builder: (ctx) => UploadSlipScreen(requestId: requestId, amount: amount),
                      ),
                    );
                  },
                  color: kPrimaryColor,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildAmountDisplay(double amount) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: kPrimaryColor.withOpacity(0.1), blurRadius: 5)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Amount to Pay:', style: TextStyle(fontSize: 18, color: kGreyText, fontWeight: FontWeight.w500)),
          Text('฿ ${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kPrimaryColor)),
        ],
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: kPrimaryColor, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15, color: kGreyText))),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBlackText)),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: kPrimaryColor,
            child: Text('$number', style: const TextStyle(color: kSurfaceColor, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 15),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16, color: kBlackText))),
        ],
      ),
    );
  }
  
  Widget _buildActionButton({required String label, required VoidCallback? onPressed, required Color color}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 5,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}