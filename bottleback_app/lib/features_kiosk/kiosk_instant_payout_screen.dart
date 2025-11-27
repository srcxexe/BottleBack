import 'package:flutter/material.dart';
import 'kiosk_success_screen.dart';

const Color kBackgroundColor = Color(0xFFF5F5F5);
const Color kPrimaryColor = Color(0xFF00796B);
const Color kBlackText = Colors.black87;

class KioskInstantPayoutScreen extends StatelessWidget {
  final double totalMoney;
  final List<Map<String, dynamic>> items;
  final String sellerId;

  const KioskInstantPayoutScreen({
    super.key,
    required this.totalMoney,
    required this.items,
    required this.sellerId,
  });

  void _completeTransaction(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => KioskSuccessScreen(
          totalMoney: totalMoney,
          items: items,
          payoutType: 'Cash',
          walletPhone: null,
          sellerId: sellerId, // ส่ง ID
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.downloading, size: 80, color: kPrimaryColor),
            const SizedBox(height: 20),
            const Text('Dispensing Cash...', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 10),
            Text('฿${totalMoney.toStringAsFixed(2)}', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => _completeTransaction(context),
              child: const Text('Simulate Collect Cash'),
            )
          ],
        ),
      ),
    );
  }
}