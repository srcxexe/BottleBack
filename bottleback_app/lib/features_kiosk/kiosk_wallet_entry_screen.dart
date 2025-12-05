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
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  // --- Core Function: นำทางไปยังหน้า Success ---
  Future<void> _submitToSuccess() async {
    final phone = _phoneController.text.trim();
    
    // Validation
    if (phone.isEmpty) {
      setState(() => _errorText = 'Please enter phone number');
      return;
    }
    if (phone.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      setState(() => _errorText = 'Phone number must be 10 digits');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    // Simulate Network Delay
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // นำทางไปยังหน้า Success เพื่อบันทึกข้อมูลจริง
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => KioskSuccessScreen(
          totalMoney: widget.totalMoney,
          items: widget.items,
          payoutType: 'Wallet',
          sellerId: widget.sellerId,
          walletPhone: phone, // ส่งเบอร์โทรไปด้วย
        ),
      ),
    );
  }

  // Helper สำหรับปุ่ม NumPad
  void _onKeyPadTap(String value) {
    if (value == 'DEL') {
      if (_phoneController.text.isNotEmpty) {
        _phoneController.text = _phoneController.text.substring(0, _phoneController.text.length - 1);
      }
    } else {
      if (_phoneController.text.length < 10) {
        _phoneController.text += value;
      }
    }
    // Clear error when typing
    if (_errorText != null) setState(() => _errorText = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Wallet Deposit', style: TextStyle(color: kBlackText)),
        backgroundColor: kBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: kBlackText),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            // Display Amount
            Text('Deposite Amount', style: TextStyle(fontSize: 16, color: kGreyText)),
            Text('฿${widget.totalMoney.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: kPrimaryColor)),
            
            const SizedBox(height: 30),

            // Phone Display Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: _errorText != null ? Colors.red : Colors.transparent),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_android, color: kPrimaryColor),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      _phoneController.text.isEmpty ? 'Enter Phone Number' : _phoneController.text,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _phoneController.text.isEmpty ? Colors.grey.shade300 : kBlackText,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_errorText!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),

            const Spacer(),

            // Custom NumPad
            CustomNumPad(onTap: _onKeyPadTap),

            const SizedBox(height: 30),

            // Action Button
            SizedBox(
              height: 60,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitToSuccess,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Confirm Deposit', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget ปุ่มกดตัวเลข
class CustomNumPad extends StatelessWidget {
  final Function(String) onTap;

  const CustomNumPad({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRow(['1', '2', '3']),
        const SizedBox(height: 15),
        _buildRow(['4', '5', '6']),
        const SizedBox(height: 15),
        _buildRow(['7', '8', '9']),
        const SizedBox(height: 15),
        _buildRow(['', '0', 'DEL']),
      ],
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        if (key.isEmpty) return const SizedBox(width: 80, height: 80);
        return _buildButton(key);
      }).toList(),
    );
  }

  Widget _buildButton(String key) {
    bool isDel = key == 'DEL';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(key),
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 80,
          height: 80,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
          ),
          child: isDel 
            ? const Icon(Icons.backspace_rounded, color: Colors.redAccent)
            : Text(key, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kBlackText)),
        ),
      ),
    );
  }
}