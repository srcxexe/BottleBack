import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'kiosk_summary_screen.dart';
import 'kiosk_login_screen.dart';

// --- Light Theme Constants ---
const Color kBackgroundColor = Color(0xFFF5F5F5); 
const Color kSurfaceColor = Colors.white;          
const Color kPrimaryColor = Color(0xFF00796B);    
const Color kBlackText = Colors.black87;           
const Color kGreyText = Colors.black54;            

// 1. กำหนดน้ำหนักมาตรฐานต่อหน่วย (กิโลกรัม) - คงเดิม
const Map<String, double> kStandardWeights = {
  'PET': 0.035,   // ~35g
  'HDPE': 0.040,  // ~40g
  'CAN': 0.015,   // ~15g
  'GLASS': 0.200, // ~200g
};

// Data Model
class KioskItem {
  final String bottleType;
  final int count;
  final double weightKg; 
  final double pricePerKg; // เปลี่ยนจาก pricePerUnit เป็น pricePerKg
  final double subTotal;

  KioskItem({
    required this.bottleType,
    required this.count,
    required this.pricePerKg,
  }) : 
    weightKg = count * (kStandardWeights[bottleType] ?? 0.0),
    subTotal = (count * (kStandardWeights[bottleType] ?? 0.0)) * pricePerKg;

  Map<String, dynamic> toMap() {
    return {
      'bottleType': bottleType,
      'count': count,
      'weightKg': weightKg,
      'pricePerKg': pricePerKg,
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
  // 2. State สำหรับเก็บราคาต่อกิโลกรัม (Default values)
  Map<String, double> _pricesPerKg = {
    'PET': 10.0,   // 10 บาท/กก.
    'HDPE': 12.0,  // 12 บาท/กก.
    'CAN': 30.0,   // 30 บาท/กก. (อลูมิเนียมแพงกว่า)
    'GLASS': 2.0,  // 2 บาท/กก.
  };

  final List<KioskItem> _items = [];

  // Controllers for Add Item Dialog
  final _countController = TextEditingController();
  String _selectedType = 'PET';

  // --- Actions ---

  void _addItem() {
    showDialog(
      context: context,
      builder: (context) {
        // ใช้ StatefulBuilder ใน Dialog เพื่อให้ UI ใน Dialog อัปเดตแบบ Realtime เมื่อกรอกเลข
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // คำนวณค่าพรีวิวทันที
            int inputCount = int.tryParse(_countController.text) ?? 0;
            double stdWeight = kStandardWeights[_selectedType] ?? 0.0;
            double currentPricePerKg = _pricesPerKg[_selectedType] ?? 0.0;
            
            double totalWeight = inputCount * stdWeight;
            double totalPrice = totalWeight * currentPricePerKg;

            return AlertDialog(
              backgroundColor: kSurfaceColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Add Items', style: TextStyle(color: kBlackText, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dropdown เลือกประเภท
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: _inputDecoration('Bottle Type'),
                      dropdownColor: kSurfaceColor,
                      items: kStandardWeights.keys.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type, style: const TextStyle(color: kBlackText)));
                      }).toList(),
                      onChanged: (val) {
                        setStateDialog(() => _selectedType = val!);
                      },
                    ),
                    const SizedBox(height: 15),

                    // ช่องกรอกจำนวน (Count Only)
                    TextFormField(
                      controller: _countController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Amount (Units)'),
                      onChanged: (val) => setStateDialog(() {}), // อัปเดตคำนวณทันที
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // --- ส่วนแสดงผลการคำนวณอัตโนมัติ ---
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: kBackgroundColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          _buildCalcRow('Standard Weight:', '${stdWeight.toStringAsFixed(3)} kg/unit'),
                          _buildCalcRow('Current Price:', '${currentPricePerKg.toStringAsFixed(2)} ฿/kg'),
                          const Divider(),
                          _buildCalcRow('Total Weight:', '${totalWeight.toStringAsFixed(2)} kg', isBold: true),
                          _buildCalcRow('Total Price:', '฿${totalPrice.toStringAsFixed(2)}', isBold: true, color: kPrimaryColor),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _countController.clear();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel', style: TextStyle(color: kGreyText)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (inputCount > 0) {
                      _saveItem(inputCount, currentPricePerKg);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: const Text('Add Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _saveItem(int count, double priceKg) {
    setState(() {
      _items.add(KioskItem(
        bottleType: _selectedType,
        count: count,
        pricePerKg: priceKg,
      ));
      _countController.clear();
    });
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  // --- Settings Dialog (ตั้งค่าราคา) ---
  void _showPriceSettings() {
    // สร้าง Controller ชั่วคราวสำหรับแต่ละประเภท
    Map<String, TextEditingController> controllers = {};
    _pricesPerKg.forEach((key, value) {
      controllers[key] = TextEditingController(text: value.toString());
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        title: const Text('Set Prices (฿/Kg)', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: kStandardWeights.keys.map((type) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: controllers[type],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _inputDecoration('Price'),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text('฿/kg', style: TextStyle(color: kGreyText)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: kGreyText)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                controllers.forEach((key, ctrl) {
                  _pricesPerKg[key] = double.tryParse(ctrl.text) ?? _pricesPerKg[key]!;
                });
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prices updated!')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
            child: const Text('Save Prices', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _navigateToSummary() {
    double totalMoney = _items.fold(0, (sum, item) => sum + item.subTotal);
    int totalCount = _items.fold(0, (sum, item) => sum + item.count);
    double totalWeight = _items.fold(0, (sum, item) => sum + item.weightKg);

    final user = FirebaseAuth.instance.currentUser;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KioskSummaryScreen(
          items: _items.map((e) => e.toMap()).toList(),
          totalCount: totalCount,
          totalWeight: totalWeight,
          totalMoney: totalMoney,
          sellerId: user?.uid ?? 'unknown_operator', 
        ),
      ),
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const KioskLoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('BottleBack Kiosk', style: TextStyle(color: kBlackText, fontWeight: FontWeight.bold)),
        backgroundColor: kSurfaceColor,
        elevation: 1,
        centerTitle: false,
        actions: [
          // ปุ่มตั้งค่าราคา
          IconButton(
            icon: const Icon(Icons.price_change_rounded, color: kPrimaryColor),
            tooltip: 'Set Prices per Kg',
            onPressed: _showPriceSettings,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          // --- Info Header ---
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kPrimaryColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: kPrimaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoColumn('Total Items', '${_items.length}', Colors.white),
                Container(height: 40, width: 1, color: Colors.white24),
                _buildInfoColumn('Current Total', '฿${_items.fold(0.0, (sum, item) => sum + item.subTotal).toStringAsFixed(2)}', Colors.white),
              ],
            ),
          ),

          // --- Add Button ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add_circle_outline, color: kPrimaryColor),
                label: const Text('Scan / Add Bottles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: kPrimaryColor,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  side: const BorderSide(color: kPrimaryColor, width: 2),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // --- List of Added Items ---
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.recycling, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 10),
                        const Text('No items added yet', style: TextStyle(color: kGreyText)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          leading: CircleAvatar(
                            backgroundColor: kPrimaryColor.withOpacity(0.1),
                            child: Text(item.bottleType[0], style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor)),
                          ),
                          title: Text('${item.bottleType} (${item.count} units)', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${item.weightKg.toStringAsFixed(2)} kg @ ฿${item.pricePerKg}/kg', 
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('฿${item.subTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kPrimaryColor)),
                              const SizedBox(width: 10),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent), 
                                onPressed: () => _removeItem(index)
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kSurfaceColor,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _items.isNotEmpty ? _navigateToSummary : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: const Text('Proceed to Summary', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      filled: true, fillColor: kBackgroundColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      labelText: label, labelStyle: const TextStyle(color: kGreyText),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
    );
  }

  Widget _buildInfoColumn(String title, String value, Color color) {
    return Column(children: [
      Text(title, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
    ]);
  }

  Widget _buildCalcRow(String label, String value, {bool isBold = false, Color color = kBlackText}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: kGreyText, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 14, color: color, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}