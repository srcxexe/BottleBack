import 'dart:io'; // จำเป็นสำหรับการจัดการไฟล์
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // สำหรับเลือกรูปภาพ
import 'package:firebase_storage/firebase_storage.dart'; // สำหรับอัปโหลดไฟล์
import 'successful_payment_screen.dart';

// --- Light Theme Constants ---\
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
  File? _imageFile; // ตัวแปรเก็บไฟล์รูปภาพที่เลือก
  final ImagePicker _picker = ImagePicker(); // ตัวเลือกรูปภาพ

  // ฟังก์ชันเลือกรูปภาพจาก Gallery
  Future<void> _selectSlip() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // ลดขนาดภาพเล็กน้อยเพื่อให้อัปโหลดเร็วขึ้น
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot pick image. Please check permissions.')),
        );
      }
    }
  }

  // ฟังก์ชันอัปโหลดรูปและบันทึกข้อมูล
  Future<void> _processPayment() async {
    if (_imageFile == null) return;

    setState(() => _isUploading = true);

    try {
      // 1. สร้างชื่อไฟล์ที่ไม่ซ้ำกัน (ใช้ timestamp)
      String fileName = 'slips/${DateTime.now().millisecondsSinceEpoch}_${widget.requestId}.jpg';
      
      // 2. อ้างอิงไปยัง Firebase Storage
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);

      // 3. เริ่มการอัปโหลด
      UploadTask uploadTask = storageRef.putFile(_imageFile!);
      
      // รอจนกว่าจะเสร็จ
      TaskSnapshot snapshot = await uploadTask;

      // 4. ดึง URL ของรูปภาพหลังจากอัปโหลดเสร็จ
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // 5. อัปเดตข้อมูลใน Firestore
      await FirebaseFirestore.instance.collection('sale_requests').doc(widget.requestId).update({
        'status': 'Paid', // เปลี่ยนสถานะเป็นจ่ายแล้ว (รอตรวจสอบ)
        'paymentDate': FieldValue.serverTimestamp(),
        'slipImageUrl': downloadUrl, // บันทึก URL รูปภาพ
      });

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SuccessfulPaymentScreen()),
        );
      }
    } catch (e) {
      debugPrint('Error uploading slip: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Upload Payment Slip', style: TextStyle(color: kBlackText, fontWeight: FontWeight.bold)),
        backgroundColor: kBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kBlackText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAmountDisplay(),
                const SizedBox(height: 30),
                const Text('Payment Proof', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBlackText)),
                const SizedBox(height: 15),
                
                // พื้นที่สำหรับเลือก/แสดงรูปภาพ
                GestureDetector(
                  onTap: _isUploading ? null : _selectSlip,
                  child: Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: kSurfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                      image: _imageFile != null
                          ? DecorationImage(
                              image: FileImage(_imageFile!), // แสดงรูปที่เลือก
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _imageFile == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload_outlined, size: 60, color: kPrimaryColor),
                              const SizedBox(height: 10),
                              const Text('Tap to upload slip', style: TextStyle(color: kGreyText, fontSize: 16)),
                            ],
                          )
                        : null, // ถ้ามีรูปแล้ว ไม่ต้องแสดง icon
                  ),
                ),
                
                const SizedBox(height: 10),
                if (_imageFile != null)
                  Center(
                    child: TextButton.icon(
                      onPressed: _isUploading ? null : _selectSlip,
                      icon: const Icon(Icons.refresh, color: kGreyText),
                      label: const Text('Change Image', style: TextStyle(color: kGreyText)),
                    ),
                  ),

                const SizedBox(height: 15),
                const Text(
                  'Please upload a clear image of the payment confirmation slip.',
                  style: TextStyle(color: kGreyText, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                // เพิ่มพื้นที่ว่างด้านล่างเพื่อให้ Scroll ได้ไม่ติดปุ่ม
                const SizedBox(height: 100), 
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
                // ปุ่มจะกดได้ก็ต่อเมื่อเลือกรูปแล้ว และไม่อยู่ระหว่างการอัปโหลด
                onPressed: (_imageFile != null && !_isUploading) ? _processPayment : null,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total Amount:', style: TextStyle(fontSize: 16, color: kGreyText)),
          Text(
            '฿ ${widget.amount.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kPrimaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required String label, required VoidCallback? onPressed, required Color color, required bool isLoading}) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24, 
                height: 24, 
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
              )
            : Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}