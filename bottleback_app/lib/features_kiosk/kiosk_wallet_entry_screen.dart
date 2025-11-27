import 'package:flutter/material.dart';
import 'kiosk_success_screen.dart'; // Import หน้าจอสำเร็จ

// --- Light Theme Constants ---
const Color kBackgroundColor = Color(0xFFF5F5F5); 
const Color kSurfaceColor = Colors.white;          
const Color kPrimaryColor = Color(0xFF00796B);    
const Color kBlackText = Colors.black87;           
const Color kGreyText = Colors.black54;            

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

  // ฟังก์ชันนำทางไปหน้า Success
  Future<void> _keepInWalletWithPhone() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    // จำลอง Delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => KioskSuccessScreen(
            totalMoney: widget.totalMoney,
            items: widget.items,
            payoutType: 'Wallet',
            walletPhone: _phoneController.text, // ส่งเบอร์โทรไปบันทึก
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
      body: SafeArea(
        child: Center(
          // ใช้ SingleChildScrollView เพื่อให้เลื่อนได้ถ้าจอเล็ก (ป้องกัน Crash)
          child: SingleChildScrollView( 
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
              child: ConstrainedBox( // จำกัดความกว้างไม่ให้ยืดจนน่าเกลียดบนจอใหญ่
                constraints: const BoxConstraints(maxWidth: 400), 
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    
                    Form(
                      key: _formKey,
                      child: TextFormField(
                        controller: _phoneController,
                        readOnly: true, // ป้องกันคีย์บอร์ดระบบเด้งขึ้นมา
                        showCursor: true,
                        style: const TextStyle(fontSize: 28, letterSpacing: 4, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: '0XXXXXXXXX',
                          hintStyle: TextStyle(color: Colors.grey.shade400, letterSpacing: 2),
                          filled: true,
                          fillColor: kSurfaceColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(vertical: 20),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter phone number';
                          if (value.length != 10) return 'Phone number must be 10 digits';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // --- Custom NumPad ---
                    // วาง Keypad ตรงนี้ โดยไม่ต้องกำหนดความสูงตายตัว
                    CustomNumPad(
                      controller: _phoneController,
                      maxLength: 10,
                    ),
        
                    const SizedBox(height: 30),
        
                    // Confirm Button
                    SizedBox(
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _keepInWalletWithPhone, 
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 3,
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
          ),
        ),
      ),
    );
  }
}

// =========================================================
// WIDGETS: Custom NumPad & KeypadButton
// =========================================================

class CustomNumPad extends StatelessWidget {
  final TextEditingController controller;
  final int maxLength;

  const CustomNumPad({super.key, required this.controller, required this.maxLength});

  void _onKeyPress(String value) {
    if (controller.text.length < maxLength) {
      controller.text += value;
    }
  }

  void _onDelete() {
    if (controller.text.isNotEmpty) {
      controller.text = controller.text.substring(0, controller.text.length - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      childAspectRatio: 1.6, // ปรับสัดส่วนปุ่มให้สวยงาม
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      padding: const EdgeInsets.all(10),
      // *** FIX CRASH KEY: 2 บรรทัดนี้สำคัญมาก ***
      shrinkWrap: true, // ให้ GridView หดตัวเท่าเนื้อหาจริง
      physics: const NeverScrollableScrollPhysics(), // ปิด Scroll ของ GridView เพื่อไม่ให้ชนกับ Parent Scroll
      children: [
        // แถว 1-3 (เลข 1-9)
        for (var i = 1; i <= 9; i++)
          KeypadButton(text: '$i', onPressed: () => _onKeyPress('$i')),
        
        // แถวล่างสุด (ว่าง, 0, ลบ)
        const SizedBox(), // ช่องว่างซ้ายล่าง
        KeypadButton(text: '0', onPressed: () => _onKeyPress('0')),
        KeypadButton(
          text: '', 
          onPressed: _onDelete, 
          isDelete: true, 
          icon: Icons.backspace_rounded,
        ),
      ],
    );
  }
}

class KeypadButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isDelete;

  const KeypadButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDelete ? Colors.red.shade50 : kSurfaceColor,
      borderRadius: BorderRadius.circular(15),
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(15),
        splashColor: kPrimaryColor.withOpacity(0.1),
        child: Center(
          child: icon != null
              ? Icon(icon, size: 28, color: isDelete ? Colors.red : kBlackText)
              : Text(
                  text,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: kBlackText,
                  ),
                ),
        ),
      ),
    );
  }
}