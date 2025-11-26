import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Light Theme Constants ---
const Color kBackgroundColor = Color(0xFFF5F5F5); 
const Color kSurfaceColor = Colors.white;          
const Color kPrimaryColor = Color(0xFF00796B);    
const Color kSecondaryColor = Color(0xFF80CBC4);  
const Color kBlackText = Colors.black87;           
const Color kGreyText = Colors.black54;            

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
      backgroundColor: kBackgroundColor, // Light background
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text('My Inventory', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBlackText)), // Dark text
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () => user != null ? showDialog(context: context, builder: (_) => AddBottleDataDialog(user: user)) : null,
      //   backgroundColor: kPrimaryColor, // Dark Teal button
      //   icon: const Icon(Icons.add_rounded, color: Colors.white), // White icon for contrast
      //   label: const Text('Add Data', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), // White text for contrast
      // ),
      body: user == null
          ? Center(child: Text('Please Login', style: TextStyle(color: kGreyText))) // Dark grey text
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('sellers').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
                final data = snapshot.data!.data() as Map<String, dynamic>;

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildModernCard('PET Bottles', data['petCount'] ?? 0, (data['petWeight'] ?? 0.0).toDouble(), Colors.blue, Icons.water_drop_outlined),
                    const SizedBox(height: 15),
                    _buildModernCard('HDPE Bottles', data['hdpeCount'] ?? 0, (data['hdpeWeight'] ?? 0.0).toDouble(), Colors.green.shade700, Icons.recycling_rounded),
                    const SizedBox(height: 15),
                    _buildModernCard('Aluminum Cans', data['canCount'] ?? 0, (data['canWeight'] ?? 0.0).toDouble(), Colors.deepOrange, Icons.sports_bar_rounded),
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
        color: kSurfaceColor, // White Card
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))], // Subtle shadow
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
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBlackText)), // Dark text
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: kBackgroundColor, borderRadius: BorderRadius.circular(20)), // Light accent background
                child: Text('${weight.toStringAsFixed(2)} kg', style: TextStyle(color: kGreyText, fontWeight: FontWeight.bold)), // Dark grey text
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
                  Text('Total Units', style: TextStyle(fontSize: 12, color: kGreyText)), // Dark grey text
                  Text('$count', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 1.2, color: kBlackText)), // Dark text
                ],
              ),
              Icon(Icons.bar_chart_rounded, size: 40, color: Colors.grey.shade300), // Light grey icon for subtle effect
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
      backgroundColor: kSurfaceColor, // White Dialog
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Add Inventory', style: TextStyle(color: kBlackText)), // Dark text
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              dropdownColor: kSurfaceColor, // Dropdown menu White
              style: const TextStyle(color: kBlackText), // Dark text
              decoration: InputDecoration(
                filled: true, fillColor: kBackgroundColor, // Light field background
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                labelText: 'Type', labelStyle: TextStyle(color: kGreyText), // Dark grey label
              ),
              items: ['PET', 'HDPE', 'CAN'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _selectedType = v),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _countController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: kBlackText), // Dark text
              decoration: InputDecoration(
                filled: true, fillColor: kBackgroundColor, // Light field background
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                labelText: 'Amount (Units)', labelStyle: TextStyle(color: kGreyText), // Dark grey label
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: kGreyText))), // Dark grey text
        ElevatedButton(
          onPressed: _saveData, 
          style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)) // White text on dark teal
        ),
      ],
    );
  }
}