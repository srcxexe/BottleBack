import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color kBackgroundColor = Color(0xFF121212);
const Color kSurfaceColor = Color(0xFF1E1E1E);
const Color kPrimaryColor = Color(0xFF00BFA5);
const Color kWhiteText = Colors.white;

class BottleCountScreen extends StatefulWidget {
  const BottleCountScreen({Key? key}) : super(key: key);

  @override
  State<BottleCountScreen> createState() => _BottleCountScreenState();
}

class _BottleCountScreenState extends State<BottleCountScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text('My Inventory', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kWhiteText)),
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => user != null ? showDialog(context: context, builder: (_) => AddBottleDataDialog(user: user)) : null,
        backgroundColor: kPrimaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.black),
        label: const Text('Add Data', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: user == null
          ? const Center(child: Text('Please Login', style: TextStyle(color: Colors.white)))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('sellers').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final data = snapshot.data!.data() as Map<String, dynamic>;

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildModernCard('PET Bottles', data['petCount'] ?? 0, (data['petWeight'] ?? 0.0).toDouble(), Colors.blueAccent, Icons.water_drop_outlined),
                    const SizedBox(height: 15),
                    _buildModernCard('HDPE Bottles', data['hdpeCount'] ?? 0, (data['hdpeWeight'] ?? 0.0).toDouble(), Colors.greenAccent, Icons.recycling_rounded),
                    const SizedBox(height: 15),
                    _buildModernCard('Aluminum Cans', data['canCount'] ?? 0, (data['canWeight'] ?? 0.0).toDouble(), Colors.redAccent, Icons.sports_bar_rounded),
                    const SizedBox(height: 80), 
                  ],
                );
              },
            ),
    );
  }

  Widget _buildModernCard(String title, int count, double weight, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurfaceColor, // Card สีเข้ม
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 15),
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kWhiteText)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text('${weight.toStringAsFixed(2)} kg', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Units', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('$count', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 1.2, color: kWhiteText)),
                ],
              ),
              Icon(Icons.bar_chart_rounded, size: 40, color: Colors.grey.shade800),
            ],
          )
        ],
      ),
    );
  }
}

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
  static const double kWeightPerBottle = 0.017;
  final Map<String, double> _pricePerKg = {'PET': 5.0, 'HDPE': 3.0, 'CAN': 10.0};

  Future<void> _saveData() async {
    // ... Logic เดิม ...
    if (!_formKey.currentState!.validate() || _selectedType == null) return;
    try {
      final int count = int.tryParse(_countController.text) ?? 0;
      final String type = _selectedType!.toLowerCase();
      final double weight = count * kWeightPerBottle;
      final double money = weight * (_pricePerKg[_selectedType] ?? 0.0);

      await FirebaseFirestore.instance.collection('sellers').doc(widget.user.uid).update({
        '${type}Count': FieldValue.increment(count),
        '${type}Weight': FieldValue.increment(weight),
        'totalMoney': FieldValue.increment(money),
        'totalWeight': FieldValue.increment(weight),
      });
      if(mounted) Navigator.pop(context);
    } catch (e) { print(e); }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: kSurfaceColor, // Dialog สีดำ
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Add Inventory', style: TextStyle(color: kWhiteText)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              dropdownColor: kSurfaceColor, // Dropdown menu สีดำ
              style: const TextStyle(color: kWhiteText),
              decoration: InputDecoration(
                filled: true, fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                labelText: 'Type', labelStyle: const TextStyle(color: Colors.grey),
              ),
              items: ['PET', 'HDPE', 'CAN'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _selectedType = v),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _countController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: kWhiteText),
              decoration: InputDecoration(
                filled: true, fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                labelText: 'Amount (Units)', labelStyle: const TextStyle(color: Colors.grey),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          onPressed: _saveData, 
          style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Add', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
        ),
      ],
    );
  }
}