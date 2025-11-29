import 'package:flutter/material.dart';
import 'kiosk_success_screen.dart'; 

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
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  // --- Logic การกดปุ่ม Numpad ---
  void _onNumberPress(String value) {
    if (_phoneController.text.length < 10) {
      setState(() {
        _phoneController.text += value;
      });
    }
  }

  void _onDeletePress() {
    if (_phoneController.text.isNotEmpty) {
      setState(() {
        _phoneController.text = _phoneController.text.substring(0, _phoneController.text.length - 1);
      });
    }
  }

  void _onClearPress() {
    setState(() {
      _phoneController.clear();
    });
  }

  Future<void> _proceedTransaction() async {
    final phone = _phoneController.text;
    
    // Validation
    if (phone.length != 10 || !phone.startsWith('0')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit phone number starting with 0.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // จำลอง Delay นิดหน่อยเพื่อให้ UX ดูลื่นไหล
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => KioskSuccessScreen(
            totalMoney: widget.totalMoney,
            items: widget.items,
            payoutType: 'Wallet',
            sellerId: widget.sellerId,
            walletPhone: phone,
          ),
        ),
      );
    }
  }

  // --- Widget ปุ่มตัวเลข ---
  Widget _buildNumPadButton(String value, {bool isAction = false, IconData? icon, VoidCallback? onTap}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Material(
          color: isAction ? Colors.transparent : Colors.white,
          elevation: isAction ? 0 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isAction ? BorderSide.none : BorderSide(color: Colors.grey.shade300),
          ),
          child: InkWell(
            onTap: onTap ?? () => _onNumberPress(value),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 70, // ความสูงปุ่ม
              alignment: Alignment.center,
              child: icon != null 
                  ? Icon(icon, size: 28, color: isAction ? Colors.red : kBlackText)
                  : Text(
                      value,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kBlackText),
                    ),
            ),
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
        title: const Text('Enter Phone Number', style: TextStyle(color: kBlackText, fontWeight: FontWeight.bold)),
        backgroundColor: kBackgroundColor, 
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: kBlackText),
      ),
      body: Column(
        children: [
          // 1. ส่วนแสดงผลเบอร์โทร (Display Area)
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 40),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Member Phone Number', style: TextStyle(color: kGreyText, fontSize: 16)),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kPrimaryColor, width: 2),
                      boxShadow: [BoxShadow(color: kPrimaryColor.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                    ),
                    child: Text(
                      _phoneController.text.isEmpty ? '0XX-XXX-XXXX' : _phoneController.text,
                      style: TextStyle(
                        fontSize: 40, 
                        fontWeight: FontWeight.bold, 
                        letterSpacing: 3,
                        color: _phoneController.text.isEmpty ? Colors.grey.shade300 : kBlackText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. แป้นตัวเลข (Numpad Grid)
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildNumPadButton('1'),
                      _buildNumPadButton('2'),
                      _buildNumPadButton('3'),
                    ],
                  ),
                  Row(
                    children: [
                      _buildNumPadButton('4'),
                      _buildNumPadButton('5'),
                      _buildNumPadButton('6'),
                    ],
                  ),
                  Row(
                    children: [
                      _buildNumPadButton('7'),
                      _buildNumPadButton('8'),
                      _buildNumPadButton('9'),
                    ],
                  ),
                  Row(
                    children: [
                      _buildNumPadButton('C', isAction: true, icon: Icons.refresh, onTap: _onClearPress),
                      _buildNumPadButton('0'),
                      _buildNumPadButton('DEL', isAction: true, icon: Icons.backspace_outlined, onTap: _onDeletePress),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 3. ปุ่มยืนยัน (Confirm Button)
          Padding(
            padding: const EdgeInsets.all(30.0),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _proceedTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('CONFIRM', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}