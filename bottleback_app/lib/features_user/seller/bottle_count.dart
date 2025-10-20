import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// เปลี่ยน StatelessWidget เป็น StatefulWidget เพื่อใช้ State ในการจัดการ Dialog
class BottleCountScreen extends StatefulWidget {
  const BottleCountScreen({Key? key}) : super(key: key);

  @override
  State<BottleCountScreen> createState() => _BottleCountScreenState();
}

class _BottleCountScreenState extends State<BottleCountScreen> {
  // --- Constants (สามารถย้ายไปไฟล์ constants.dart ได้) ---
  final Color kBackgroundColor = const Color(0xFFB2F5E6);
  final Color kPrimaryColor = const Color(0xFF00BFA5);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor:kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Color(0xFFFFFFFF),
        elevation: 0,
        title: const Text(
          'Bottles Count',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        automaticallyImplyLeading: false, 
      ),
      body: SafeArea(
        child: user == null
            ? const Center(child: Text('User not logged in.'))
            : StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('sellers')
                    .doc(user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(
                        child: Text('Seller data not found.'));
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final petCount = data['petCount'] ?? 0;
                  final petWeight = (data['petWeight'] ?? 0.0).toDouble();
                  final hdpeCount = data['hdpeCount'] ?? 0;
                  final hdpeWeight = (data['hdpeWeight'] ?? 0.0).toDouble();
                  final canCount = data['canCount'] ?? 0;
                  final canWeight = (data['canWeight'] ?? 0.0).toDouble();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAddDataButton(context, user),
                        const SizedBox(height: 30),

                        _buildBottleSection(
                          type: 'PET Bottles',
                          count: petCount,
                          weight: petWeight,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(height: 20),

                        _buildBottleSection(
                          type: 'HDPE Bottles',
                          count: hdpeCount,
                          weight: hdpeWeight,
                          color: Colors.yellow.shade700,
                        ),
                        const SizedBox(height: 20),

                        _buildBottleSection(
                          type: 'CAN',
                          count: canCount,
                          weight: canWeight,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  // --- Widget สำหรับปุ่ม Add Data ---
  Widget _buildAddDataButton(BuildContext context, User user) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () => _showAddBottleDialog(context, user),
        icon: const Icon(Icons.add_circle_outline, color: Colors.white),
        label: const Text(
          'Add Bottle Data',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor, 
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // --- Dialog สำหรับกรอกข้อมูลขวดใหม่ ---
  void _showAddBottleDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddBottleDataDialog(user: user);
      },
    );
  }

  // --- Widget สำหรับแสดงข้อมูลแต่ละประเภท ---
  Widget _buildBottleSection({
    required String type,
    required int count,
    required double weight,
    required Color color,
  }) {
    // โค้ดส่วนนี้ไม่มีการเปลี่ยนแปลง
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 6,
                backgroundColor: color,
              ),
              const SizedBox(width: 8),
              Text(
                type,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildInfoBox(
                  value: count.toString(),
                  label: 'units',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoBox(
                  value: '${weight.toStringAsFixed(2)} kg', 
                  label: 'weight',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox({required String value, required String label}) {
    // โค้ดส่วนนี้ไม่มีการเปลี่ยนแปลง
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: kBackgroundColor.withOpacity(0.5), 
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Widget ใหม่: Dialog สำหรับกรอกข้อมูล (แก้ไขตามระบบคำนวณใหม่)
// -----------------------------------------------------------------------------

class AddBottleDataDialog extends StatefulWidget {
  final User user;
  const AddBottleDataDialog({Key? key, required this.user}) : super(key: key);

  @override
  State<AddBottleDataDialog> createState() => _AddBottleDataDialogState();
}

class _AddBottleDataDialogState extends State<AddBottleDataDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedType;
  final _countController = TextEditingController();
  // ลบ _weightController เพราะไม่ใช้แล้ว
  bool _isSaving = false;

  final List<String> _bottleTypes = ['PET', 'HDPE', 'CAN']; 

  // *** ค่าคงที่ใหม่: 1 ขวด = 0.017 กิโลกรัม ***
  static const double kWeightPerBottle = 0.017;

  // กำหนดราคาต่อหน่วย/กิโลกรัม 
  final Map<String, double> _pricePerKg = {
    'PET': 5.0, 
    'HDPE': 3.0, 
    'CAN': 10.0, 
  };
  
  @override
  void dispose() {
    _countController.dispose();
    // ลบ _weightController.dispose();
    super.dispose();
  }


  // Logic การบันทึกข้อมูล
  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select bottle type.')),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      final int count = int.tryParse(_countController.text) ?? 0;
      final String type = _selectedType!.toLowerCase(); 

      // 1. คำนวณน้ำหนัก (Weight)
      final double weight = count * kWeightPerBottle;
      
      // 2. คำนวณยอดเงินที่เพิ่ม (Money)
      // ใช้ราคาต่อกิโลกรัม * น้ำหนักที่คำนวณได้
      final double pricePerKg = _pricePerKg[_selectedType] ?? 0.0;
      final double moneyToAdd = weight * pricePerKg; 

      // 3. อัปเดตข้อมูลใน Firestore
      await FirebaseFirestore.instance
          .collection('sellers')
          .doc(widget.user.uid)
          .update({
        // เพิ่มจำนวนขวดและน้ำหนักที่คำนวณ
        '${type}Count': FieldValue.increment(count),
        '${type}Weight': FieldValue.increment(weight),
        
        // อัปเดตยอดเงินและน้ำหนักรวม
        'totalMoney': FieldValue.increment(moneyToAdd),
        'totalWeight': FieldValue.increment(weight),
      });

      if (mounted) {
        Navigator.of(context).pop(); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $count ${type.toUpperCase()} bottles (${weight.toStringAsFixed(3)} kg)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color kPrimaryColor = Color(0xFF00BFA5); 

    return AlertDialog(
      title: const Text('Add Bottle Data'), // เปลี่ยนเป็น Data แทน Weight/Bottle Data
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Dropdown สำหรับเลือกประเภทขวด
              DropdownButtonFormField<String>(
                value: _selectedType,
                hint: const Text('Select Bottle Type *'),
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: _bottleTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) => setState(() => _selectedType = value),
                validator: (value) => value == null ? 'Required' : null,
              ),
              const SizedBox(height: 15),

              // จำนวนขวด (นับเป็นชิ้น) 
              TextFormField(
                controller: _countController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Number of Bottles (units)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final number = int.tryParse(value ?? '');
                  if (number == null || number <= 0) {
                    return 'Enter a valid count > 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // *** แสดงคำนวณน้ำหนักให้ผู้ใช้เห็น (Optional: เพื่อยืนยัน) ***
              Text(
                'Calculated Weight: ${(int.tryParse(_countController.text) ?? 0) * kWeightPerBottle} kg',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveData,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}