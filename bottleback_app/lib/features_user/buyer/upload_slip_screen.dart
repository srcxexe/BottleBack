import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'successful_payment_screen.dart'; 
// import 'package:image_picker/image_picker.dart'; // สำหรับแอปจริงต้องใช้
// import 'dart:io'; // สำหรับแอปจริงต้องใช้

// --- Light Theme Constants ---
const Color kBackgroundColor = Color(0xFFF5F5F5); 
const Color kSurfaceColor = Colors.white;          
const Color kPrimaryColor = Color(0xFF00796B);    
const Color kBlackText = Colors.black87;           
const Color kGreyText = Colors.black54; 

class UploadSlipScreen extends StatefulWidget {
  final String requestId;
  final double amount;

  const UploadSlipScreen({Key? key, required this.requestId, required this.amount}) : super(key: key);

  @override
  State<UploadSlipScreen> createState() => _UploadSlipScreenState();
}

class _UploadSlipScreenState extends State<UploadSlipScreen> {
  bool _isUploading = false;
  // Placeholder for File Path (จำลองการเลือกไฟล์)
  String? _selectedFilePath; 

  Future<void> _selectSlip() async {
    // *** NOTE: ในแอปพลิเคชันจริง คุณต้องใช้ library เช่น image_picker หรือ file_picker ***
    // เช่น: final XFile? file = await ImagePicker().pickImage(source: ImageSource.gallery);
    // และใช้ path ของไฟล์จริง
    
    // สำหรับโค้ดตัวอย่างนี้ เราจะจำลองการเลือกไฟล์
    setState(() {
      _selectedFilePath = 'slip_${widget.requestId}_${DateTime.now().millisecondsSinceEpoch}.jpg'; 
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Slip selected! (Simulated)'), backgroundColor: kPrimaryColor));
    }
  }

  Future<void> _processPayment() async {
    if (_selectedFilePath == null) return;

    setState(() => _isUploading = true);

    try {
      // *** NOTE: ในแอปพลิเคชันจริง คุณต้องอัปโหลดไฟล์ไปที่ Firebase Storage ที่นี่ก่อน ***
      // เช่น: final ref = FirebaseStorage.instance.ref().child('slips/$_selectedFilePath');
      // await ref.putFile(File(_selectedFilePath!));
      // final downloadUrl = await ref.getDownloadURL();
      
      // Update Firestore Request Status
      await FirebaseFirestore.instance.collection('sale_requests').doc(widget.requestId).update({
        'status': 'Paid',
        'paymentDate': FieldValue.serverTimestamp(),
        // 'slipImageUrl': downloadUrl, // ในแอปจริง ต้องใช้ URL จริง
        'slipImageUrl': 'https://example.com/slips/$_selectedFilePath', // จำลอง URL
      });

      if (mounted) {
        // นำทางไปหน้าสำเร็จ และแทนที่หน้าปัจจุบันเพื่อไม่ให้ย้อนกลับมาได้
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SuccessfulPaymentScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading slip: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Upload Payment Slip', style: TextStyle(color: kBlackText, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: kBackgroundColor, elevation: 0, centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kBlackText, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAmountDisplay(),
                const SizedBox(height: 25),

                // Upload Area
                Text('Payment Slip', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBlackText)),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: _isUploading ? null : _selectSlip,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    decoration: BoxDecoration(
                      color: kSurfaceColor,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: _selectedFilePath != null ? kPrimaryColor : kGreyText.withOpacity(0.5), width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_rounded,
                          size: 50,
                          color: _selectedFilePath != null ? kPrimaryColor : kGreyText,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _selectedFilePath ?? 'Tap to select payment slip',
                          style: TextStyle(color: _selectedFilePath != null ? kBlackText : kGreyText, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                const Text('Please upload a clear image of the payment confirmation slip.', style: TextStyle(color: kGreyText, fontSize: 12)),
              ],
            ),
          ),
          
          // Action Button at Bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: kSurfaceColor,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: _buildActionButton(
                label: 'Confirm & Send',
                onPressed: _selectedFilePath != null && !_isUploading ? _processPayment : null,
                color: kPrimaryColor,
                isLoading: _isUploading,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildAmountDisplay() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: kPrimaryColor.withOpacity(0.1), blurRadius: 5)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Amount:', style: TextStyle(fontSize: 18, color: kGreyText)),
          Text('฿ ${widget.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kPrimaryColor)),
        ],
      ),
    );
  }
  
  Widget _buildActionButton({required String label, required VoidCallback? onPressed, required Color color, required bool isLoading}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 5,
        ),
        child: isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: kSurfaceColor))
            : Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}