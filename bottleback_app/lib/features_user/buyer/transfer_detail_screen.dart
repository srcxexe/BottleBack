import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'upload_slip_screen.dart';

// --- Constants ---
const Color kBackgroundColor = Color(0xFFB2F5E6); 
const Color kPrimaryColor = Color(0xFF00BFA5); 
const Color kDarkTextColor = Colors.black87;

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
        title: const Text('Transfer Details', style: TextStyle(color: kDarkTextColor, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchSellerBankData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Error loading seller bank data.'));
          }

          final sellerData = snapshot.data!;
          final bank = sellerData['bank'] ?? 'N/A';
          final bankNo = sellerData['bankNo'] ?? 'N/A';
          final accountName = sellerData['name'] ?? 'N/A';

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAmountCard(amount),
                    const SizedBox(height: 30),
                    
                    const Text('Bank Account Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kDarkTextColor)),
                    const SizedBox(height: 10),

                    _buildBankCard(bank, bankNo, accountName),
                    const SizedBox(height: 20),

                    const Text('Steps:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kDarkTextColor)),
                    _buildStep(1, 'Transfer ฿ ${amount.toStringAsFixed(2)} to the account above.'),
                    _buildStep(2, 'Capture the transfer slip.'),
                    _buildStep(3, 'Click "Upload Slip" to complete payment.'),
                    
                    const SizedBox(height: 100),
                  ],
                ),
              ),

              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: _buildActionButton(
                    label: 'Upload Slip',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UploadSlipScreen(
                            requestId: requestId,
                            amount: amount,
                          ),
                        ),
                      );
                    },
                    color: kPrimaryColor,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAmountCard(double amount) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: kPrimaryColor, width: 2),
        boxShadow: [
          BoxShadow(color: kPrimaryColor.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            const Text('Amount Due:', style: TextStyle(fontSize: 18, color: Colors.black54)),
            const SizedBox(height: 5),
            Text(
              '฿ ${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w900,
                color: kPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBankCard(String bank, String bankNo, String accountName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          _buildBankDetailRow('Bank Name', bank, Icons.account_balance),
          const Divider(),
          _buildBankDetailRow('Account No.', bankNo, Icons.credit_card),
          const Divider(),
          _buildBankDetailRow('Account Name', accountName, Icons.person),
        ],
      ),
    );
  }

  Widget _buildBankDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: kPrimaryColor),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15, color: Colors.black54))),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kDarkTextColor)),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: kPrimaryColor,
            child: Text('$number', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16, color: kDarkTextColor))),
        ],
      ),
    );
  }

  Widget _buildActionButton({required String label, required VoidCallback? onPressed, required Color color}) {
    // ... (ปุ่มเหมือนเดิมจากหน้า Request Detail) ...
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
}