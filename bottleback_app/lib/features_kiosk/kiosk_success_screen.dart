import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'kiosk_main_screen.dart'; // กลับไปหน้าหลัก Kiosk

// --- Light Theme Constants ---
const Color kBackgroundColor = Color(0xFFF5F5F5);
const Color kSurfaceColor = Colors.white;
const Color kPrimaryColor = Color.fromARGB(255, 118, 212, 201);
const Color kBlackText = Colors.black87;
const Color kGreyText = Colors.black54;

class KioskSuccessScreen extends StatefulWidget {
  final double totalMoney;
  final List<Map<String, dynamic>> items;
  final String payoutType; // 'Cash' or 'Wallet'
  final String sellerId; // ID ของผู้ปฏิบัติงาน Kiosk (Operator)
  final String? walletPhone;

  const KioskSuccessScreen({
    super.key,
    required this.totalMoney,
    required this.items,
    required this.payoutType,
    required this.sellerId, 
    this.walletPhone,
  });

  @override
  State<KioskSuccessScreen> createState() => _KioskSuccessScreenState();
}

class _KioskSuccessScreenState extends State<KioskSuccessScreen> {
  bool _isSaving = true;
  String _statusMessage = 'Processing transaction...';
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    // เรียกใช้ฟังก์ชันบันทึกข้อมูลทันทีที่หน้านี้เปิดขึ้นมา
    _saveTransaction();
  }

  // *** FIX CRASH: ใช้ Sequential Writes แทน Transaction เพื่อแก้ปัญหา Threading บน Desktop ***
  Future<void> _saveTransaction() async {
    // 1. ตรวจสอบเงื่อนไขพื้นฐาน
    if (widget.sellerId.isEmpty) {
      if (mounted) setState(() { _isError = true; _isSaving = false; _statusMessage = 'Fatal Error: Operator ID is missing.'; });
      return;
    }

    try {
      // 2. บันทึก Transaction History ก่อน
      final transactionRef = FirebaseFirestore.instance.collection('kiosk_transactions').doc();
      final transactionData = {
        'id': transactionRef.id,
        'timestamp': FieldValue.serverTimestamp(),
        'sellerId': widget.sellerId,
        'totalMoney': widget.totalMoney,
        'payoutType': widget.payoutType,
        'walletPhone': widget.walletPhone,
        'items': widget.items,
        'status': 'Completed',
        'kioskId': 'KIOSK_01', 
      };
      
      await transactionRef.set(transactionData);

      // 3. ถ้าเป็น Wallet Deposit ให้ทำการค้นหาและอัปเดตยอดเงิน
      if (widget.payoutType == 'Wallet' && widget.walletPhone != null) {
        
        // A. ค้นหา User (ต้องทำก่อนอัปเดต)
        final userQuery = await FirebaseFirestore.instance
            .collection('sellers') 
            .where('phone', isEqualTo: widget.walletPhone)
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          final userDoc = userQuery.docs.first;
          final currentBalance = (userDoc.data()['walletBalance'] ?? 0.0) as num;
          final double newBalance = currentBalance.toDouble() + widget.totalMoney;
          
          // B. อัปเดตยอดเงิน (ใช้ .update() โดยตรง)
          await userDoc.reference.update({
            'walletBalance': newBalance,
            'lastUpdate': FieldValue.serverTimestamp(),
          });
          
          if (mounted) {
            _statusMessage = 'Transaction Successful! Funds deposited to Wallet.';
          }
        } else {
          // ไม่พบ user ใน DB
          if (mounted) {
             _statusMessage = 'Success (History Recorded), but Wallet update failed (Phone not found).';
          }
        }
      } else if (widget.payoutType == 'Cash') {
          if (mounted) {
            _statusMessage = 'Transaction Successful! Cash Dispensed.';
          }
      }

      // 4. เสร็จสิ้นการบันทึกข้อมูล
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }

    } catch (e) {
      // 5. จัดการ Error
      print("CRITICAL FIRESTORE ERROR: $e");
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isError = true;
          _statusMessage = 'System Error: Data saving failed. Status: $e'; // แสดง Error ในหน้าจอ
        });
      }
    }
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
              // Icon Status
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kSurfaceColor,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Icon(
                  _isSaving ? Icons.hourglass_top_rounded 
                  : (_isError ? Icons.error_outline : Icons.check_circle_rounded),
                  size: 80,
                  color: _isSaving ? Colors.orange 
                  : (_isError ? Colors.red : kPrimaryColor),
                ),
              ),
              
              const SizedBox(height: 30),
              
              Text(
                _isSaving ? 'Processing...' : (_isError ? 'Transaction Failed' : 'Success!'),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kBlackText),
              ),
              
              const SizedBox(height: 15),
              
              // Message
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: _isError ? Colors.red : kGreyText),
              ),

              const SizedBox(height: 40),

              // Transaction Details
              if (!_isSaving && !_isError) 
                Card(
                  color: kSurfaceColor,
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Payout Type: ${widget.payoutType}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (widget.payoutType == 'Wallet') 
                          Text('Wallet Phone: ${widget.walletPhone}', style: const TextStyle(color: kGreyText)),
                        const Divider(),
                        Text('Amount: ฿${widget.totalMoney.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: kPrimaryColor)),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 50),
              
              // Home Button
              if (!_isSaving)
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      // กลับไปหน้าหลักและล้าง Stack
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const KioskMainScreen()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 5,
                    ),
                    child: const Text('Return to Home', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}