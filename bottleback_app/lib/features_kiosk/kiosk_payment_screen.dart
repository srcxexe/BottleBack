import 'package:flutter/material.dart';
import 'kiosk_instant_payout_screen.dart';
import 'kiosk_wallet_entry_screen.dart';

// --- Light Theme Constants ---
const Color kBackgroundColor = Color(0xFFF5F5F5);
const Color kSurfaceColor = Colors.white;
const Color kPrimaryColor = Color(0xFF00796B);
const Color kBlackText = Colors.black87;
const Color kGreyText = Colors.black54;
const Color kAccentColor = Color(0xFF80CBC4);

class KioskPaymentScreen extends StatelessWidget {
  final double totalMoney;
  final List<Map<String, dynamic>> items;
  final String sellerId; // ID ของ Kiosk Operator

  const KioskPaymentScreen({
    super.key,
    required this.totalMoney,
    required this.items,
    required this.sellerId,
  });

  Widget _buildPaymentCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: kGreyText),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Choose Payout Method', style: TextStyle(color: kBlackText, fontWeight: FontWeight.bold)),
        backgroundColor: kBackgroundColor, elevation: 0, centerTitle: true,
        iconTheme: const IconThemeData(color: kBlackText),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select how you want to receive payment:',
              style: TextStyle(fontSize: 18, color: kBlackText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // 1. Instant Cash Payout
            _buildPaymentCard(
              icon: Icons.money_rounded,
              title: 'Instant Cash Payout',
              subtitle: 'Receive money immediately from the Kiosk.',
              color: kPrimaryColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => KioskInstantPayoutScreen(
                      totalMoney: totalMoney,
                      items: items,
                      sellerId: sellerId, // ส่ง sellerId ไปด้วย
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            // 2. Deposit to Wallet
            _buildPaymentCard(
              icon: Icons.account_balance_wallet_rounded,
              title: 'Deposit to Wallet',
              subtitle: 'Deposit money into your app wallet using your phone number.',
              color: kAccentColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => KioskWalletEntryScreen(
                      totalMoney: totalMoney,
                      items: items,
                      sellerId: sellerId,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}