import 'package:flutter/material.dart';
import 'kiosk_main_screen.dart'; // เตรียมไว้สำหรับไปหน้า Main ต่อไป
import '../features_kiosk/kiosk_summary_screen.dart';
import '../services/websocket_service.dart';
// --- Light Theme Constants ---
const Color kBackgroundColor = Color(0xFFF5F5F5); 
const Color kPrimaryColor = Color(0xFF80CBC4);    
const Color kBlackText = Colors.black87; 
final WebSocketService _webSocketService = WebSocketService();
class KioskInsertScreen extends StatefulWidget {
  const KioskInsertScreen({super.key});

  @override
  State<KioskInsertScreen> createState() => _KioskInsertScreenState();
}
  void initState() {
    _webSocketService.connect();
  }
class _KioskInsertScreenState extends State<KioskInsertScreen> {
  
  void _finishInsertion() {
    // เมื่อหยอดขวดเสร็จ ไปหน้าสรุปรายการ (Main Screen)
    _webSocketService.sendMessage("END");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => KioskSummaryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Insert Bottles', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kPrimaryColor,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context), // กลับไปหน้า Landing (ถ้าไม่ได้ใช้ pushReplacement)
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.arrow_circle_down_rounded, size: 100, color: kPrimaryColor),
            const SizedBox(height: 30),
            const Text(
              'Please Insert Your Bottles',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBlackText),
            ),
            const SizedBox(height: 10),
            const Text(
              'Waiting for machine...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 50),
            
            // ปุ่มจำลองการทำงานเสร็จสิ้น
            ElevatedButton(
              onPressed: _finishInsertion,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Finish / Next', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}