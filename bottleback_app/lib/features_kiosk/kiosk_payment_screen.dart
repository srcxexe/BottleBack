import 'package:flutter/material.dart';
import 'kiosk_instant_payout_screen.dart';
import 'kiosk_wallet_entry_screen.dart';

const Color kBackgroundColor = Color(0xFFF5F5F5);
const Color kSurfaceColor = Colors.white;
const Color kPrimaryColor = Color(0xFF00796B);
const Color kBlackText = Colors.black87;
const Color kGreyText = Colors.black54;

class KioskPaymentScreen extends StatelessWidget {
  final double totalMoney;
  final List<Map<String, dynamic>> items;
  final String sellerId;

  const KioskPaymentScreen({
    super.key,
    required this.totalMoney,
    required this.items,
    required this.sellerId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Payment Method', style: TextStyle(color: kBlackText)),
        backgroundColor: kBackgroundColor, elevation: 0,
        iconTheme: const IconThemeData(color: kBlackText),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Total: ฿${totalMoney.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kPrimaryColor)),
            const SizedBox(height: 30),
            
            // Cash Button
            _buildButton(
              context, 
              'Instant Cash', 
              Icons.money, 
              () => Navigator.push(context, MaterialPageRoute(builder: (context) => KioskInstantPayoutScreen(
                totalMoney: totalMoney, 
                items: items, 
                sellerId: sellerId // ส่ง ID
              )))
            ),
            
            const SizedBox(height: 20),

            // Wallet Button
            _buildButton(
              context, 
              'Deposit to Wallet', 
              Icons.account_balance_wallet, 
              () => Navigator.push(context, MaterialPageRoute(builder: (context) => KioskWalletEntryScreen(
                totalMoney: totalMoney, 
                items: items, 
                sellerId: sellerId // ส่ง ID (สำคัญมากสำหรับหน้า Wallet)
              )))
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 4,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        leading: Icon(icon, size: 40, color: kPrimaryColor),
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}