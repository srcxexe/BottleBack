import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'successful_payment_screen.dart';

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
  // Placeholder for File
  String? _selectedFilePath; 

  Future<void> _selectSlip() async {
    // In a real app, you would use file_picker or image_picker here
    // For now, we simulate file selection
    setState(() {
      _selectedFilePath = 'slip_image_12345.jpg'; 
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Slip selected! (Simulated)')));
    }
  }

  Future<void> _processPayment() async {
    if (_selectedFilePath == null) return;
    
    setState(() => _isUploading = true);

    try {
      // Simulate Upload process and update Firestore
      await FirebaseFirestore.instance.collection('sale_requests').doc(widget.requestId).update({
        'status': 'Paid',
        'paymentDate': FieldValue.serverTimestamp(),
        'slipImageUrl': 'https://placehold.co/600x400/00796B/FFFFFF?text=Payment+Slip+Uploaded', // Simulated Image URL
      });

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SuccessfulPaymentScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete payment: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildAmountDisplay() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
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
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text('Upload Payment Slip', style: TextStyle(color: kBlackText, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kBlackText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAmountDisplay(),
                const SizedBox(height: 30),
                
                // Upload Area
                GestureDetector(
                  onTap: _selectSlip,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: kSurfaceColor,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: _selectedFilePath != null ? kPrimaryColor : Colors.grey.shade300, width: 2),
                      boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectedFilePath != null ? Icons.check_circle_rounded : Icons.camera_alt_rounded,
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
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],// เงา
              ),
              child: SafeArea(
                top: false,
                child: _buildActionButton(
                  label: 'Confirm & Send',
                  onPressed: _selectedFilePath != null && !_isUploading ? _processPayment : null,
                  color: kPrimaryColor,
                  isLoading: _isUploading,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}