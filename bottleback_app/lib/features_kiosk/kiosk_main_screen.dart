import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; // FIX 1: Import Firebase Auth
import 'kiosk_summary_screen.dart';

// --- Light Theme Constants ---
const Color kBackgroundColor = Color(0xFFF5F5F5); 
const Color kSurfaceColor = Colors.white;          
const Color kPrimaryColor = Color(0xFF80CBC4);    
const Color kBlackText = Colors.black87;           
const Color kGreyText = Colors.black54;            

// 1. กำหนดน้ำหนักมาตรฐานต่อหน่วย (กิโลกรัม)
const Map<String, double> kStandardWeights = {
  'PET': 0.035,   // ประมาณ 35 กรัมต่อขวด
  'HDPE': 0.040,  // ประมาณ 40 กรัมต่อขวด
  'CAN': 0.015,   // ประมาณ 15 กรัมต่อกระป๋อง
  'GLASS': 0.200, // ประมาณ 200 กรัมต่อขวด
};

// Data Model สำหรับบันทึกรายการขวดที่ถูกสแกน/กรอก
class KioskItem {
  final String bottleType;
  final int count;
  final double weightKg; // Calculated property
  final double pricePerUnit; 
  final double subTotal;

  // แก้ไข constructor ให้คำนวณ weightKg และ subTotal
  KioskItem({
    required this.bottleType,
    required this.count,
    required this.pricePerUnit,
  }) : 
    weightKg = count * (kStandardWeights[bottleType] ?? 0.0), // ใช้ ?? 0.0 เพื่อความปลอดภัย
    subTotal = count * pricePerUnit;

  // เมท็อดสำหรับแปลงเป็น Map เพื่อส่งไปยังหน้า Summary/Payment
  Map<String, dynamic> toMap() {
    return {
      'bottleType': bottleType,
      'count': count,
      'weightKg': weightKg,
      'pricePerUnit': pricePerUnit,
      'subTotal': subTotal,
    };
  }
}


class KioskMainScreen extends StatefulWidget {
  const KioskMainScreen({super.key});

  @override
  State<KioskMainScreen> createState() => _KioskMainScreenState();
}

class _KioskMainScreenState extends State<KioskMainScreen> {
  final List<KioskItem> _items = [];
  final String _sellerId = FirebaseAuth.instance.currentUser?.uid ?? 'kiosk_guest_01'; // FIX 2: ใช้ Firebase Auth

  double get _totalMoney => _items.fold(0.0, (sum, item) => sum + item.subTotal);
  int get _totalCount => _items.fold(0, (sum, item) => sum + item.count);
  double get _totalWeight => _items.fold(0.0, (sum, item) => sum + item.weightKg);

  void _addItem(KioskItem item) {
    // รวมรายการเดียวกัน หากมีอยู่แล้ว
    final existingIndex = _items.indexWhere((i) => i.bottleType == item.bottleType && i.pricePerUnit == item.pricePerUnit);
    
    if (existingIndex != -1) {
      // Logic การรวมรายการ หากต้องการรวมจำนวนและคำนวณใหม่
      // แต่ในตัวอย่างนี้จะใช้การเพิ่มรายการใหม่เข้าไปเลยเพื่อให้ง่ายต่อการแสดงผล
      setState(() {
        _items.add(item);
      });
    } else {
      setState(() {
        _items.add(item);
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.count} units of ${item.bottleType} added. Subtotal: ฿${item.subTotal.toStringAsFixed(2)}'), backgroundColor: kPrimaryColor)
    );
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }
  
  void _navigateToSummary() {
    // แปลงรายการ KioskItem เป็น Map<String, dynamic> ก่อนส่ง
    final List<Map<String, dynamic>> itemsMap = _items.map((item) => item.toMap()).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KioskSummaryScreen(
          items: itemsMap,
          totalCount: _totalCount,
          totalWeight: _totalWeight,
          totalMoney: _totalMoney,
          sellerId: _sellerId, // ส่ง sellerId
        ),
      ),
    );
  }

  // Dialog สำหรับกรอกข้อมูลรายการ
  Future<void> _showAddItemDialog() async {
    final _dialogFormKey = GlobalKey<FormState>();
    String? _selectedType = kStandardWeights.keys.first;
    final _countController = TextEditingController();
    final _priceController = TextEditingController();

    // กำหนดราคาเริ่มต้นตามประเภทที่เลือก (ถ้ามี)
    // ในที่นี้เราจะให้กรอกราคาเองเพื่อความยืดหยุ่น
    _priceController.text = ''; 

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Recyclable Item'),
          content: SingleChildScrollView(
            child: Form(
              key: _dialogFormKey,
              child: ListBody(
                children: <Widget>[
                  // Bottle Type Dropdown
                  DropdownButtonFormField<String>(
                    decoration: _inputDecoration('Bottle Type'),
                    value: _selectedType,
                    items: kStandardWeights.keys.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text('$value (Std. Weight: ${kStandardWeights[value]} kg)'),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedType = newValue;
                      });
                    },
                    validator: (v) => v == null ? 'Select a type' : null,
                  ),
                  const SizedBox(height: 15),

                  // Amount (Units)
                  TextFormField(
                    controller: _countController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Amount (Units)'),
                    validator: (v) {
                      if (v!.isEmpty || int.tryParse(v) == null || (int.tryParse(v) ?? 0) <= 0) return 'Enter a valid number (> 0)';
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),

                  // Price Per Unit (฿)
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Price Per Unit (฿)'),
                    validator: (v) {
                      if (v!.isEmpty || double.tryParse(v) == null) return 'Enter a valid price';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: kGreyText))),
            ElevatedButton(
              onPressed: () {
                if (_dialogFormKey.currentState!.validate()) {
                  final newItem = KioskItem(
                    bottleType: _selectedType!,
                    count: int.parse(_countController.text),
                    pricePerUnit: double.parse(_priceController.text),
                  );
                  _addItem(newItem);
                  Navigator.pop(context);
                }
              }, 
              style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('Add Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
            ),
          ],
        );
      },
    );
  }
  
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      filled: true, fillColor: kSurfaceColor, // ใช้ kSurfaceColor เป็นสีพื้นหลังใน dialog
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      labelText: label, labelStyle: const TextStyle(color: kGreyText),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Kiosk Recycling Station', style: TextStyle(color: kBlackText, fontWeight: FontWeight.bold)),
        backgroundColor: kSurfaceColor, 
        elevation: 1,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: kPrimaryColor),
            onPressed: _showAddItemDialog,
            tooltip: 'Add Item Manually',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Summary
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Card(
              color: kSurfaceColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryBox('Total Units', _totalCount.toString(), Colors.blueGrey),
                    _buildSummaryBox('Total Weight (Kg)', _totalWeight.toStringAsFixed(3), Colors.orange),
                    _buildSummaryBox('Total Money (฿)', _totalMoney.toStringAsFixed(2), kPrimaryColor),
                  ],
                ),
              ),
            ),
          ),

          // Item List
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text('No items added. Start recycling!', style: TextStyle(color: kGreyText, fontSize: 18)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 0),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Card(
                        color: kSurfaceColor,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.bottleType,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBlackText),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.count} units @ ฿${item.pricePerUnit.toStringAsFixed(2)}/unit',
                                      style: const TextStyle(color: kGreyText, fontSize: 14),
                                    ),
                                    Text(
                                      'Weight: ${item.weightKg.toStringAsFixed(3)} kg',
                                      style: const TextStyle(color: kGreyText, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '฿${item.subTotal.toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kPrimaryColor),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () {
                                  _removeItem(index);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Item removed.'), backgroundColor: Colors.red)
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            decoration: BoxDecoration(
              color: kSurfaceColor,
              boxShadow: [BoxShadow(color: const Color.fromARGB(28, 0, 0, 0), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: SizedBox(
              height: 55,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _items.isNotEmpty ? _navigateToSummary : null,
                icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                label: const Text('Proceed to Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 14, color: kGreyText)),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}