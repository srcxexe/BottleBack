import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'kiosk_main_screen.dart'; 

const Color kBackgroundColor = Color(0xFFF5F5F5);
const Color kSurfaceColor = Colors.white;
const Color kPrimaryColor = Color(0xFF00796B);
const Color kBlackText = Colors.black87;
const Color kGreyText = Colors.black54;

class KioskSuccessScreen extends StatefulWidget {
  final double totalMoney;
  final List<Map<String, dynamic>> items;
  final String payoutType; 
  final String sellerId;
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
  String _statusMessage = 'Initializing transaction...';
  String? _transactionRefId; // เก็บ ID เพื่อโชว์ว่าบันทึกจริง
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _saveTransaction();
  }

  Future<void> _saveTransaction() async {
    try {
      print("--- START SAVING TRANSACTION ---");
      setState(() => _statusMessage = 'Connecting to database...');

      // 1. คำนวณยอดรวม
      int totalBottles = 0;
      double totalWeight = 0.0;
      for (var item in widget.items) {
        totalBottles += (item['count'] as int? ?? 0);
        totalWeight += (item['weightKg'] as double? ?? 0.0);
      }

      final firestore = FirebaseFirestore.instance;

      if (widget.payoutType == 'Wallet' && widget.walletPhone != null) {
         // --- Case Wallet ---
         print("Processing Wallet Transaction for ${widget.walletPhone}");
         
         await firestore.runTransaction((transaction) async {
            // A. หา User (Query ต้องใช้ await ในการดึง snapshot ก่อนเข้า transaction block หรือใช้ get ใน transaction)
            final userQuery = await firestore.collection('sellers')
                .where('phone', isEqualTo: widget.walletPhone)
                .limit(1)
                .get(); // Note: get() here allows reading user doc
            
            if (userQuery.docs.isEmpty) {
               throw Exception('User not found during transaction!');
            }

            final userDoc = userQuery.docs.first;
            final userRef = userDoc.reference;

            // B. อัปเดตเงิน
            transaction.update(userRef, {
              'walletBalance': FieldValue.increment(widget.totalMoney),
              'totalBottles': FieldValue.increment(totalBottles),
              // 'totalWeight': FieldValue.increment(totalWeight), // Uncomment if field exists
              'lastUpdate': FieldValue.serverTimestamp(),
            });

            // C. สร้างประวัติ (ใช้ doc() เปล่าๆ เพื่อสร้าง ID ใหม่)
            final newHistoryRef = firestore.collection('sale_requests').doc();
            transaction.set(newHistoryRef, {
              'sellerId': userDoc.id,
              'sellerName': userDoc.data()['name'] ?? 'Unknown',
              'phone': widget.walletPhone,
              'type': 'Deposit',
              'payoutType': 'Wallet',
              'status': 'Completed',
              'items': widget.items,
              'money': widget.totalMoney,
              'count': totalBottles,
              'weight': totalWeight,
              'timestamp': FieldValue.serverTimestamp(),
              'kioskId': widget.sellerId,
            });
            
            // เก็บ ID ไว้แสดงผล (ต้องทำนอก transaction scope หรือกำหนดค่าตัวแปร)
            _transactionRefId = newHistoryRef.id;
         });

      } else {
         // --- Case Cash ---
         print("Processing Cash Transaction");
         final docRef = await firestore.collection('sale_requests').add({
            'sellerId': 'WALK_IN', 
            'sellerName': 'Walk-in Customer',
            'type': 'Deposit',
            'payoutType': 'Cash',
            'status': 'Completed',
            'items': widget.items,
            'money': widget.totalMoney,
            'count': totalBottles,
            'weight': totalWeight,
            'timestamp': FieldValue.serverTimestamp(),
            'kioskId': widget.sellerId,
         });
         _transactionRefId = docRef.id;
      }

      print("--- SAVE SUCCESS: ID $_transactionRefId ---");

      if (mounted) {
        setState(() { 
          _isSaving = false; 
          _statusMessage = 'Success!'; 
          _isError = false;
        });
      }

    } catch (e) {
      print("--- SAVE ERROR: $e ---");
      if (mounted) {
        setState(() { 
          _isSaving = false; 
          _statusMessage = 'Error: $e'; 
          _isError = true;
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
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isSaving ? Icons.hourglass_top : (_isError ? Icons.error_outline : Icons.check_circle),
                size: 100,
                color: _isSaving ? Colors.orange : (_isError ? Colors.red : kPrimaryColor),
              ),
              const SizedBox(height: 30),
              Text(
                _isSaving ? 'Processing...' : (_isError ? 'Transaction Failed' : 'Transaction Complete'),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kBlackText),
              ),
              const SizedBox(height: 10),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: _isError ? Colors.red : kGreyText),
              ),
              
              if (!_isSaving && !_isError) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
                  child: Column(
                    children: [
                      if (_transactionRefId != null)
                        Text('Ref ID: ${_transactionRefId!.substring(0, 8)}...', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 5),
                      Text(widget.payoutType == 'Wallet' ? 'Added to Wallet: ${widget.walletPhone}' : 'Cash Payment', style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor)),
                      const SizedBox(height: 5),
                      Text('+ ฿${widget.totalMoney.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBlackText)),
                    ],
                  ),
                )
              ],

              const SizedBox(height: 50),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () {
                    // ถ้า Error ให้ลองใหม่ (pop), ถ้าสำเร็จให้กลับหน้าหลัก (pushAndRemoveUntil)
                    if (_isError) {
                       Navigator.pop(context); // กลับไปลองใหม่
                    } else {
                       Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const KioskMainScreen()),
                        (route) => false,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isError ? Colors.orange : kPrimaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Text(_isError ? 'Try Again' : 'Return to Home', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}