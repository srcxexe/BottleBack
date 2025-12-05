import 'package:bottleback_app/services/websocket_service.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'kiosk_success_screen.dart';

// --- Light Theme Constants ---
const Color kBackgroundColor = Color(0xFFF5F5F5);
const Color kPrimaryColor = Color(0xFF00796B);
const Color kBlackText = Colors.black87;
const Color kGreyText = Colors.black54;
final WebSocketService _webSocketService = WebSocketService();
class KioskInstantPayoutScreen extends StatelessWidget {
  final double totalMoney;
  final List<Map<String, dynamic>> items;
  final String sellerId;
  void initState() {
    _webSocketService.connect();
  }
  const KioskInstantPayoutScreen({
    super.key,
    required this.totalMoney,
    required this.items,
    required this.sellerId,
  });

  void _completeTransaction(BuildContext context) {
    // นำทางไปยังหน้า Success เพื่อบันทึกข้อมูล
  
    _webSocketService.sendMessage(totalMoney.toInt().toString());
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => KioskSuccessScreen(
          totalMoney: totalMoney,
          items: items,
          payoutType: 'Cash',
          walletPhone: null,
          sellerId: sellerId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_atm_rounded, size: 100, color: kPrimaryColor),
              const SizedBox(height: 30),
              const Text(
                'Dispensing Cash...',
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
                'Please collect your cash below.\nTransaction will complete automatically.',
                style: TextStyle(fontSize: 16, color: kGreyText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),

              SizedBox(
                height: 55,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _completeTransaction(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('Receive Cash & Finish', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}