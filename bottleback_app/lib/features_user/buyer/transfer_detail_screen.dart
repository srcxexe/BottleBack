import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'upload_slip_screen.dart';

// --- Light Theme Constants ---\
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
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
          if (!snapshot.hasData || snapshot.data == null) return const Center(child: Text('Seller bank info not found', style: TextStyle(color: kGreyText)));

          final bankData = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bank Info Card
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: kSurfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Column(
                    children: [
                      const Text('Transfer Amount', style: TextStyle(color: kGreyText)),
                      const SizedBox(height: 10),
                      Text('฿ ${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: kPrimaryColor)),
                      const SizedBox(height: 25),
                      const Divider(color: kBackgroundColor),
                      const SizedBox(height: 15),
                      _buildDetailRow(icon: Icons.account_balance_rounded, label: 'Bank Name', value: bankData['bank'] ?? 'N/A'),
                      const SizedBox(height: 15),
                      _buildDetailRow(icon: Icons.credit_card_rounded, label: 'Account No.', value: bankData['bankNo'] ?? 'N/A'),
                      const SizedBox(height: 15),
                      _buildDetailRow(icon: Icons.person_rounded, label: 'Account Name', value: bankData['name'] ?? 'N/A'),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // Steps
                const Text('Steps to Complete Transfer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBlackText)),
                const SizedBox(height: 15),
                _buildStep(1, 'Transfer the exact amount to the bank account above via your banking app.'),
                _buildStep(2, 'Save the payment slip (screenshot).'),
                _buildStep(3, 'Click "Upload Slip" below to submit proof.'),
                
                const Spacer(),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => UploadSlipScreen(requestId: requestId, amount: amount),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 5,
                    ),
                    child: const Text('Upload Slip', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, color: kPrimaryColor, size: 20),
        const SizedBox(width: 15),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 15, color: kGreyText))),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBlackText)),
      ],
    );
  }

  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: kPrimaryColor.withOpacity(0.2),
            child: Text('$number', style: const TextStyle(color: kPrimaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 15),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: kBlackText))),
        ],
      ),
    );
  }
}