import 'package:flutter/material.dart';
import 'kiosk_success_screen.dart';

// --- Light Theme Constants ---\
const Color kBackgroundColor = Color(0xFFF5F5F5);
const Color kPrimaryColor = Color(0xFF80CBC4);
const Color kBlackText = Colors.black87;
const Color kGreyText = Colors.black54;

class KioskInstantPayoutScreen extends StatelessWidget {
  final double totalMoney;
  final List<Map<String, dynamic>> items;
  final String sellerId; // รับ sellerId

  const KioskInstantPayoutScreen({
    super.key,
    required this.totalMoney,
    required this.items,
    required this.sellerId, // กำหนดให้รับ sellerId
  });

  // Function to simulate transaction completion and move to success screen
  void _completeTransaction(BuildContext context) {
    // สำหรับการจำลอง: นำทางไปยังหน้าสำเร็จทันที
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => KioskSuccessScreen(
          totalMoney: totalMoney,
          items: items,
          payoutType: 'Cash',
          walletPhone: null, // ไม่มีเบอร์โทร
          sellerId: sellerId, // ส่ง sellerId ไปด้วย
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Instant Cash Payout', style: TextStyle(color: kBlackText, fontWeight: FontWeight.bold)),
        backgroundColor: kBackgroundColor, elevation: 0, centerTitle: true,
        iconTheme: const IconThemeData(color: kBlackText),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.money_rounded, size: 100, color: Colors.green),
              const SizedBox(height: 30),
              const Text(
                'Please wait while the Kiosk dispenses',
                style: TextStyle(fontSize: 20, color: kBlackText, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                '฿${totalMoney.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.green),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              const Text(
                'Please take your cash and receipt. This transaction will be marked as "Completed" immediately.',
                style: TextStyle(fontSize: 16, color: kGreyText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),

              // ปุ่มจำลองการเสร็จสิ้น
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: () => _completeTransaction(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('Simulate Cash Received & Finish', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}