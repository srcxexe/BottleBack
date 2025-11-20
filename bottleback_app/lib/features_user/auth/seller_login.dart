import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'seller_register.dart';
import '../seller/dashboard.dart';

// --- Dark Theme Constants ---
const Color kBackgroundColor = Color(0xFF121212);
const Color kSurfaceColor = Color(0xFF1E1E1E);
const Color kPrimaryColor = Color(0xFF00BFA5);
const Color kWhiteText = Colors.white;
const Color kGreyText = Colors.grey;
const Color kInputFillColor = Color(0xFF2C2C2C);

class SellerLoginScreen extends StatefulWidget {
  const SellerLoginScreen({Key? key}) : super(key: key);

  @override
  State<SellerLoginScreen> createState() => _SellerLoginScreenState();
}

class _SellerLoginScreenState extends State<SellerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // Logic เดิม: แปลงเบอร์โทรเป็น email
      final email = '${_phoneController.text}@bottleback.com';
      
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SellerDashboard()));
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Login Failed';
      if (e.code == 'user-not-found') message = 'User not found';
      else if (e.code == 'wrong-password') message = 'Incorrect password';
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kWhiteText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Seller Login', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: kWhiteText)),
                const SizedBox(height: 10),
                const Text('Manage your recyclable sales', style: TextStyle(fontSize: 16, color: kGreyText)),
                const SizedBox(height: 40),
                
                // Login Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: kSurfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        icon: Icons.phone_iphone_rounded,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_rounded,
                        isPassword: true,
                      ),
                      const SizedBox(height: 30),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                              : const Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("New Seller? ", style: TextStyle(color: kGreyText)),
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SellerRegisterScreen())),
                              child: const Text('Register now', style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      keyboardType: keyboardType,
      style: const TextStyle(color: kWhiteText),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: kGreyText),
        prefixIcon: Icon(icon, color: kPrimaryColor),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: kGreyText),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        filled: true,
        fillColor: kInputFillColor, // สีพื้นหลัง Input เข้ม
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kPrimaryColor, width: 1.5)),
      ),
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
    );
  }
}