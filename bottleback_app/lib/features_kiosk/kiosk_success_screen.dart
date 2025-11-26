import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'kiosk_main_screen.dart'; // กลับไปหน้าหลัก Kiosk

// --- Light Theme Constants ---\
const Color kBackgroundColor = Color(0xFFF5F5F5);
const Color kSurfaceColor = Colors.white;
const Color kPrimaryColor = Color(0xFF80CBC4);
const Color kBlackText = Colors.black87;
const Color kGreyText = Colors.black54;

// กำหนดน้ำหนักมาตรฐานต่อหน่วย (กิโลกรัม) - คัดลอกจาก KioskMainScreen
const Map<String, double> kStandardWeights = {
  'PET': 0.035,   
  'HDPE': 0.040,  
  'CAN': 0.015,   
  'GLASS': 0.200, 
};

class KioskSuccessScreen extends StatefulWidget {
  final double totalMoney;
  final List<Map<String, dynamic>> items;
  final String payoutType; // 'Cash' or 'Wallet'
  final String sellerId; // ID ของผู้ปฏิบัติงาน Kiosk
  final String? walletPhone;

  const KioskSuccessScreen({
    super.key,
    required this.totalMoney,
    required this.items,
    required this.payoutType,
    required this.sellerId, // รับ sellerId
    this.walletPhone,
  });

  @override
  State<KioskSuccessScreen> createState() => _KioskSuccessScreenState();
}

class _KioskSuccessScreenState extends State<KioskSuccessScreen> {
  bool _isSaving = true;
  String _statusMessage = 'Processing transaction...';

  @override
  void initState() {
    super.initState();
    _saveTransaction();
  }

  // *** FUNCTION: บันทึกข้อมูลลง Firestore ***
  Future<void> _saveTransaction() async {
    // 1. คำนวณน้ำหนักรวมและหน่วยรวมจาก items
    double calculatedTotalWeight = 0.0;
    int calculatedTotalCount = 0;
    for (var item in widget.items) {
      calculatedTotalWeight += item['weightKg'] as double;
      calculatedTotalCount += item['count'] as int;
    }
    
    // 2. สร้างข้อมูลที่จะบันทึก
    final transactionData = {
      'timestamp': FieldValue.serverTimestamp(),
      'sellerId': widget.sellerId,
      'status': 'Completed', // ถือว่าสำเร็จในหน้านี้แล้ว
      'payoutType': widget.payoutType,
      'totalMoney': widget.totalMoney,
      'totalCount': calculatedTotalCount,
      'totalWeight': calculatedTotalWeight,
      'items': widget.items,
      'walletPhone': widget.walletPhone, // จะเป็น null ถ้าจ่ายด้วยเงินสด
    };

    // 3. บันทึกเข้า Firestore
    try {
      // สร้างเอกสารใหม่ใน collection 'sale_transactions'
      await FirebaseFirestore.instance.collection('sale_transactions').add(transactionData);

      // 4. (Wallet Deposit Only) อัปเดตยอดเงินใน Wallet ของผู้ใช้
      if (widget.payoutType == 'Wallet' && widget.walletPhone != null) {
        // ในระบบจริงต้องหา User ID จากเบอร์โทรศัพท์ก่อน
        // แต่ในการจำลองนี้ เราจะใช้เบอร์โทรศัพท์เป็น ID ชั่วคราวในการอัปเดต Wallet
        // *** ข้อควรระวัง: ในการผลิตจริง ไม่ควรใช้เบอร์โทรศัพท์เป็น ID หลักใน Firestore ***
        final walletRef = FirebaseFirestore.instance.collection('user_wallets').doc(widget.walletPhone);
        
        // ใช้ Transaction เพื่อให้การอัปเดตข้อมูลเป็นไปอย่างปลอดภัย (Atomic)
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snapshot = await transaction.get(walletRef);
          double currentBalance = (snapshot.exists ? snapshot.get('balance') : 0.0) as double;
          
          double newBalance = currentBalance + widget.totalMoney;

          if (snapshot.exists) {
            transaction.update(walletRef, {
              'balance': newBalance,
              'lastUpdate': FieldValue.serverTimestamp(),
            });
          } else {
            transaction.set(walletRef, {
              'phone': widget.walletPhone,
              'balance': newBalance,
              'lastUpdate': FieldValue.serverTimestamp(),
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        });
        setState(() {
          _statusMessage = 'Transaction completed and ฿${widget.totalMoney.toStringAsFixed(2)} deposited to wallet.';
        });
      } else {
        setState(() {
          _statusMessage = 'Transaction completed and cash dispensed.';
        });
      }

    } catch (e) {
      setState(() {
        _statusMessage = 'Error during saving transaction: $e';
      });
      // ในแอปจริงควรมี Retry Mechanism หรือ Log Error
    } finally {
      setState(() {
        _isSaving = false;
      });
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon
              Icon(
                _isSaving ? Icons.hourglass_top_rounded : Icons.check_circle_rounded,
                size: 100,
                color: _isSaving ? Colors.orange : kPrimaryColor,
              ),
              const SizedBox(height: 30),

              // Status Message
              Text(
                _isSaving ? 'Processing...' : 'Transaction Successful!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: _isSaving ? Colors.orange : kBlackText,
                ),
              ),
              const SizedBox(height: 10),

              // Detail Message
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: kGreyText),
              ),
              const SizedBox(height: 30),

              if (!_isSaving) ...[
                // Success Payout Message
                Text(
                  widget.payoutType == 'Cash'
                      ? 'You have received ฿${widget.totalMoney.toStringAsFixed(2)} in cash.'
                      : '฿${widget.totalMoney.toStringAsFixed(2)} deposited to wallet associated with ${widget.walletPhone}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 60),
              
              // Finish Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () {
                    // กลับไปหน้าแรกของ Kiosk โดยล้าง Stack
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const KioskMainScreen()),
                      (Route<dynamic> route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                  ),
                  child: const Text('Finish', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}