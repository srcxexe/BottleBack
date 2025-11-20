import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Dark Theme Constants ---
const Color kBackgroundColor = Color(0xFF121212);
const Color kSurfaceColor = Color(0xFF1E1E1E);
const Color kPrimaryColor = Color(0xFF00BFA5);
const Color kWhiteText = Colors.white;
const Color kGreyText = Colors.grey;
const Color kInputFillColor = Color(0xFF2C2C2C);

class SellerRegisterScreen extends StatefulWidget {
  const SellerRegisterScreen({Key? key}) : super(key: key);

  @override
  State<SellerRegisterScreen> createState() => _SellerRegisterScreenState();
}

class _SellerRegisterScreenState extends State<SellerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _selectedBank;
  final _bankNoController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final List<String> _banks = [
    'ธนาคารกรุงเทพ', 'ธนาคารกสิกรไทย', 'ธนาคารไทยพาณิชย์',
    'ธนาคารกรุงไทย', 'ธนาคารทหารไทยธนชาต', 'ธนาคารกรุงศรีอยุธยา',
    'ธนาคารเกียรตินาคินภัทร', 'ธนาคารซีไอเอ็มบีไทย', 'ธนาคารทิสโก้', 'ธนาคารยูโอบี',
  ];

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเลือกธนาคาร')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = '${_phoneController.text}@bottleback.com';
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: _passwordController.text,
      );

      await FirebaseFirestore.instance.collection('sellers').doc(credential.user!.uid).set({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'bank': _selectedBank,
        'bankNo': _bankNoController.text,
        'createdAt': FieldValue.serverTimestamp(),
        'totalWeight': 0.0, 'totalMoney': 0.0,
        'petCount': 0, 'hdpeCount': 0, 'canCount': 0,
        'petWeight': 0.0, 'hdpeWeight': 0.0, 'canWeight': 0.0,
      });

      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 20, color: kWhiteText),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(height: 20),
                Text(
                  _currentStep == 0 ? 'Seller Register\nStep 1: Info' : 'Seller Register\nStep 2: Bank',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: kWhiteText, height: 1.2),
                ),
                const SizedBox(height: 30),
                
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _currentStep == 0 ? _buildStep1() : _buildStep2(),
                ),
                
                const SizedBox(height: 30),
                Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => setState(() => _currentStep = 0),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade800,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Back', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () {
                            if (_currentStep == 0) {
                              if (_formKey.currentState!.validate()) setState(() => _currentStep = 1);
                            } else {
                              _register();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                              : Text(_currentStep == 0 ? 'Next' : 'Register', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: kSurfaceColor, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Personal Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: kWhiteText)),
          const SizedBox(height: 20),
          _buildTextField(_nameController, 'Name', Icons.person_rounded),
          const SizedBox(height: 20),
          _buildTextField(_phoneController, 'Phone', Icons.phone_rounded, isNumber: true),
          const SizedBox(height: 20),
          _buildTextField(_passwordController, 'Password', Icons.lock_rounded, isPassword: true, isObscure: _obscurePassword, toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword)),
          const SizedBox(height: 20),
          _buildTextField(_confirmPasswordController, 'Confirm Password', Icons.lock_outline, isPassword: true, isObscure: _obscureConfirmPassword, toggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: kSurfaceColor, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bank Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: kWhiteText)),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _selectedBank,
            dropdownColor: kSurfaceColor, // เมนู Dropdown สีมืด
            style: const TextStyle(color: kWhiteText),
            decoration: InputDecoration(
              labelText: 'Select Bank',
              labelStyle: const TextStyle(color: kGreyText),
              filled: true,
              fillColor: kInputFillColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              prefixIcon: const Icon(Icons.account_balance_rounded, color: kPrimaryColor),
            ),
            items: _banks.map((bank) => DropdownMenuItem(value: bank, child: Text(bank))).toList(),
            onChanged: (value) => setState(() => _selectedBank = value),
            validator: (value) => value == null ? 'Required' : null,
          ),
          const SizedBox(height: 20),
          _buildTextField(_bankNoController, 'Bank Account No.', Icons.numbers_rounded, isNumber: true),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false, bool? isObscure, VoidCallback? toggleObscure, bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? (isObscure ?? true) : false,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: kWhiteText),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: kGreyText),
        prefixIcon: Icon(icon, color: kPrimaryColor),
        suffixIcon: isPassword ? IconButton(icon: Icon(isObscure! ? Icons.visibility_off : Icons.visibility, color: kGreyText), onPressed: toggleObscure) : null,
        filled: true,
        fillColor: kInputFillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kPrimaryColor, width: 1.5)),
      ),
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
    );
  }
}