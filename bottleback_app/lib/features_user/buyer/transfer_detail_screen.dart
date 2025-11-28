import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'upload_slip_screen.dart';

// --- Light Theme Constants ---
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

  Future<Map<String, dynamic>?> _fetchSellerBankData() async {
    final doc = await FirebaseFirestore.instance.collection('sellers').doc(sellerId).get();
    return doc.exists ? doc.data() : null;
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
            child: Text('$number', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 15),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16, color: kGreyText))),
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
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('Error: Seller bank data not found.', style: TextStyle(color: kBlackText)));
          }

          final bankData = snapshot.data!;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount to Transfer
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Amount to Transfer', style: TextStyle(fontSize: 18, color: Colors.white70)),
                      Text('฿ ${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // Bank Details
                Text('Seller Bank Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBlackText)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: kSurfaceColor,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(icon: Icons.person_rounded, label: 'Account Holder', value: bankData['name'] ?? 'N/A'),
                      const Divider(color: Colors.black12),
                      _buildDetailRow(icon: Icons.account_balance_rounded, label: 'Bank Name', value: bankData['bank'] ?? 'N/A'),
                      const Divider(color: Colors.black12),
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
}