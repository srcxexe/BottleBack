import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:image_picker/image_picker.dart'; // ต้อง import สำหรับการเลือกรูปภาพจริง
// import 'package:firebase_storage/firebase_storage.dart'; // ต้อง import สำหรับการอัปโหลดรูปภาพจริง
import 'successful_payment_screen.dart';

// --- Constants ---
const Color kBackgroundColor = Color(0xFFB2F5E6); 
const Color kPrimaryColor = Color(0xFF00BFA5); 
const Color kDarkTextColor = Colors.black87;

class UploadSlipScreen extends StatefulWidget {
  final String requestId;
  final double amount;

  const UploadSlipScreen({
    Key? key,
    required this.requestId,
    required this.amount,
  }) : super(key: key);

  @override
  State<UploadSlipScreen> createState() => _UploadSlipScreenState();
}

class _UploadSlipScreenState extends State<UploadSlipScreen> {
  // XFile? _imageFile; // สำหรับเก็บไฟล์รูปภาพจริง
  bool _isUploading = false;

  // *** ฟังก์ชันจำลองการอัปโหลดสลิปและการอัปเดตสถานะ ***
  Future<void> _processPayment() async {
    // if (_imageFile == null) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Please select a slip image first.')),
    //   );
    //   return;
    // }

    setState(() => _isUploading = true);

    try {
      // 1. (โค้ดจริง) อัปโหลดรูปภาพไปที่ Firebase Storage และรับ URL
      // String imageUrl = await _uploadImageToStorage(_imageFile!);

      // 2. อัปเดตสถานะใน Firestore
      await FirebaseFirestore.instance.collection('sale_requests').doc(widget.requestId).update({
        'status': 'Paid', // เปลี่ยนสถานะเป็น Paid
        // 'paymentSlipUrl': imageUrl, // (โค้ดจริง) เก็บ URL สลิป
        'paymentDate': FieldValue.serverTimestamp(),
        // 'paidByBuyerId': FirebaseAuth.instance.currentUser?.uid,
      });

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const SuccessfulPaymentScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e')),
        );
      }
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text('Upload Slip', style: TextStyle(color: kDarkTextColor, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAmountDisplay(),
                const SizedBox(height: 30),
                
                const Text('Please upload your transfer slip below:', 
                  style: TextStyle(fontSize: 16, color: kDarkTextColor)
                ),
                const SizedBox(height: 15),

                // *** Card สำหรับการอัปโหลดรูปภาพ (ใช้ Icon จำลอง) ***
                Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_rounded, size: 60, color: kPrimaryColor.withOpacity(0.6)),
                        const SizedBox(height: 10),
                        const Text(
                          'Tap to select slip image',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
                // (โค้ดจริง: แสดงรูปที่เลือกแทน Icon)
                
                const SizedBox(height: 100),
              ],
            ),
          ),
          
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: _buildActionButton(
                label: _isUploading ? 'Processing...' : 'Confirm Payment',
                onPressed: _isUploading ? null : _processPayment,
                color: kPrimaryColor,
                isLoading: _isUploading,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountDisplay() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Amount:',
            style: TextStyle(fontSize: 18, color: Colors.black54),
          ),
          Text(
            '฿ ${widget.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required String label, required VoidCallback? onPressed, required Color color, required bool isLoading}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                label,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
      ),
    );
  }
}