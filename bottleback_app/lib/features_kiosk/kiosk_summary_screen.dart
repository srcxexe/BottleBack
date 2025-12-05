import 'package:flutter/material.dart';
import 'kiosk_payment_screen.dart'; 

// --- Light Theme Constants ---
const Color kBackgroundColor = Color(0xFFF5F5F5);
const Color kSurfaceColor = Colors.white;
const Color kPrimaryColor = Color(0xFF00796B);
const Color kBlackText = Colors.black87;
const Color kGreyText = Colors.black54;           

class KioskSummaryScreen extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final int totalCount;
  final double totalWeight;
  final double totalMoney;
  final String sellerId;

  const KioskSummaryScreen({
    super.key,
    required this.items,
    required this.totalCount,
    required this.totalWeight,
    required this.totalMoney,
    required this.sellerId,
  });

  void _navigateToPayment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KioskPaymentScreen(
          totalMoney: totalMoney,
          items: items,
          sellerId: sellerId, // ส่ง ID ต่อไป
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Summary', style: TextStyle(color: kBlackText)),
        backgroundColor: kSurfaceColor, 
        elevation: 0, 
        centerTitle: true,
        iconTheme: const IconThemeData(color: kBlackText),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('Order Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const Divider(),
                    ...items.map((e) => ListTile(
                      title: Text('${e['bottleType']} x ${e['count']}'),
                      trailing: Text('฿${(e['subTotal'] as double).toStringAsFixed(2)}'),
                    )),
                    const Divider(),
                    ListTile(
                      title: const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text('฿${totalMoney.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor, fontSize: 18)),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => _navigateToPayment(context),
                style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
                child: const Text('Confirm & Pay', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            )
          ],
        ),
      ),
    );
  }
}