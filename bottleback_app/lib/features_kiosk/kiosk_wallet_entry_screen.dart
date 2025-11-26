import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // REMOVED: ไม่ใช้ Firestore ในหน้านี้โดยตรง
import 'kiosk_success_screen.dart'; // Import หน้าจอสำเร็จ

// --- Light Theme Constants (copied from KioskSummaryScreen) ---
const Color kBackgroundColor = Color(0xFFF5F5F5); 
const Color kSurfaceColor = Colors.white;          
const Color kPrimaryColor = Color(0xFF80CBC4);    
const Color kBlackText = Colors.black87;           
const Color kGreyText = Colors.black54;            

// กำหนดน้ำหนักมาตรฐานต่อหน่วย (กิโลกรัม) - คัดลอกมาจาก KioskMainScreen
const Map<String, double> kStandardWeights = {
  'PET': 0.035,   
  'HDPE': 0.040,  
  'CAN': 0.015,   
  'GLASS': 0.200, 
};

class KioskWalletEntryScreen extends StatefulWidget {
  final double totalMoney;
  final List<Map<String, dynamic>> items;
  final String sellerId;

  const KioskWalletEntryScreen({
    super.key,
    required this.totalMoney,
    required this.items,
    required this.sellerId,
  });

  @override
  State<KioskWalletEntryScreen> createState() => _KioskWalletEntryScreenState();
}

class _KioskWalletEntryScreenState extends State<KioskWalletEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  
  // --- Core Function: บันทึกเข้า Wallet (เปลี่ยนเป็นการนำทาง) ---
  Future<void> _keepInWalletWithPhone() async {
    if (!_formKey.currentState!.validate()) return;
    
    // ในแอปพลิเคชันจริง: 
    // 1. ตรวจสอบเบอร์โทรศัพท์กับระบบสมาชิก
    // 2. ถ้ามีผู้ใช้จริง: ดำเนินการโอนเงินเข้า Wallet 
    // 3. บันทึกข้อมูลลง Firestore โดยมี status: 'Pending' หรือ 'Completed' และ type: 'Wallet'
    
    setState(() => _isLoading = true);

    // สำหรับการจำลอง: นำทางไปยังหน้าสำเร็จทันที
    await Future.delayed(const Duration(milliseconds: 1500)); // Simulate API delay
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => KioskSuccessScreen(
            totalMoney: widget.totalMoney,
            items: widget.items,
            payoutType: 'Wallet',
            walletPhone: _phoneController.text, // ส่งเบอร์โทร
            sellerId: widget.sellerId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Deposit to Wallet', style: TextStyle(color: kBlackText, fontWeight: FontWeight.bold)),
        backgroundColor: kBackgroundColor, elevation: 0, centerTitle: true,
        iconTheme: const IconThemeData(color: kBlackText),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.account_balance_wallet_rounded, size: 80, color: kPrimaryColor),
              const SizedBox(height: 20),
              Text(
                'Deposit Amount: ฿${widget.totalMoney.toStringAsFixed(2)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kPrimaryColor),
              ),
              const SizedBox(height: 30),
              const Text(
                'Enter the 10-digit phone number linked to your app wallet to proceed with the deposit.',
                style: TextStyle(fontSize: 16, color: kGreyText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  style: const TextStyle(fontSize: 20, color: kBlackText, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Phone Number (10 digits)',
                    labelStyle: const TextStyle(color: kGreyText),
                    prefixIcon: Icon(Icons.phone, color: kPrimaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    counterText: '', // ซ่อน counter
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter phone number';
                    }
                    if (value.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
                      return 'Phone number must be 10 digits';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 40),

              // Action Button
              SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _keepInWalletWithPhone, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text('Confirm Deposit', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}