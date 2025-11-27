import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'kiosk_summary_screen.dart';
import 'kiosk_login_screen.dart'; // Import หน้า Login เผื่อต้องเด้งกลับ

// --- Light Theme Constants ---
const Color kBackgroundColor = Color(0xFFF5F5F5); 
const Color kSurfaceColor = Colors.white;          
const Color kPrimaryColor = Color.fromARGB(255, 118, 212, 201);    
const Color kBlackText = Colors.black87;           
const Color kGreyText = Colors.black54;            

// 1. กำหนดน้ำหนักมาตรฐานต่อหน่วย (กิโลกรัม)
const Map<String, double> kStandardWeights = {
  'PET': 0.035,
  'HDPE': 0.040,
  'CAN': 0.015,
  'GLASS': 0.200,
};

// Data Model
class KioskItem {
  final String bottleType;
  final int count;
  final double weightKg;
  final double pricePerUnit; 
  final double subTotal;

  KioskItem({
    required this.bottleType,
    required this.count,
    required this.pricePerUnit,
  }) : 
    weightKg = count * (kStandardWeights[bottleType] ?? 0.0),
    subTotal = count * pricePerUnit;

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
  String? _sellerId;
  bool _isLoading = true;

  double get _totalMoney => _items.fold(0.0, (sum, item) => sum + item.subTotal);
  int get _totalCount => _items.fold(0, (sum, item) => sum + item.count);
  double get _totalWeight => _items.fold(0.0, (sum, item) => sum + item.weightKg);

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() {
    // ฟังสถานะ Auth ตลอดเวลา
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _sellerId = user?.uid;
          _isLoading = false;
        });
      }
    });
  }

  void _addItem(KioskItem item) {
    setState(() {
      _items.add(item);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${item.count} ${item.bottleType}'), duration: const Duration(seconds: 1), backgroundColor: kPrimaryColor)
    );
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }
  
  void _navigateToSummary() {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item.'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_sellerId == null) {
      // ถ้าไม่มี User ให้เด้งไปหน้า Login
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const KioskLoginScreen()));
      return;
    }

    // แปลงข้อมูลและส่ง sellerId ไป
    final List<Map<String, dynamic>> itemsMap = _items.map((item) => item.toMap()).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KioskSummaryScreen(
          items: itemsMap,
          totalCount: _totalCount,
          totalWeight: _totalWeight,
          totalMoney: _totalMoney,
          sellerId: _sellerId!, // ส่ง ID ที่ถูกต้อง
        ),
      ),
    );
  }

  // Dialog Add Item
  Future<void> _showAddItemDialog() async {
    final dialogFormKey = GlobalKey<FormState>();
    String? selectedType = kStandardWeights.keys.first;
    final countController = TextEditingController();
    final priceController = TextEditingController(text: '1.0');

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Recyclable Item'),
          content: SingleChildScrollView(
            child: Form(
              key: dialogFormKey,
              child: ListBody(
                children: <Widget>[
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                    value: selectedType,
                    items: kStandardWeights.keys.map((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                    onChanged: (v) => selectedType = v,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: countController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Count', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Price/Unit', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (dialogFormKey.currentState!.validate()) {
                  _addItem(KioskItem(
                    bottleType: selectedType!,
                    count: int.parse(countController.text),
                    pricePerUnit: double.parse(priceController.text),
                  ));
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (_sellerId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Please Log In"),
              ElevatedButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const KioskLoginScreen())), child: const Text("Login"))
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Kiosk Recycling', style: TextStyle(color: kBlackText, fontWeight: FontWeight.bold)),
        backgroundColor: kSurfaceColor, 
        elevation: 1,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: kPrimaryColor),
            onPressed: _showAddItemDialog,
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
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoColumn('Count', '$_totalCount', Colors.blueGrey),
                    _buildInfoColumn('Weight', '${_totalWeight.toStringAsFixed(2)} kg', Colors.orange),
                    _buildInfoColumn('Money', '฿${_totalMoney.toStringAsFixed(2)}', kPrimaryColor),
                  ],
                ),
              ),
            ),
          ),
          
          Expanded(
            child: _items.isEmpty 
              ? const Center(child: Text('No items added', style: TextStyle(color: kGreyText)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text('${item.bottleType} (${item.count})'),
                        subtitle: Text('฿${item.subTotal.toStringAsFixed(2)}'),
                        trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeItem(index)),
                      ),
                    );
                  },
                ),
          ),

          Container(
            padding: const EdgeInsets.all(20),
            color: kSurfaceColor,
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _items.isNotEmpty ? _navigateToSummary : null,
                style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: const Text('Proceed to Summary', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String title, String value, Color color) {
    return Column(children: [
      Text(title, style: const TextStyle(fontSize: 12, color: kGreyText)),
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
    ]);
  }
}