import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'buyer_login.dart'; 

// --- Dark Theme Constants ---
const Color kBackgroundColor = Color(0xFF121212);
const Color kSurfaceColor = Color(0xFF1E1E1E);
const Color kPrimaryColor = Color(0xFF00BFA5);
const Color kWhiteText = Colors.white;
const Color kGreyText = Colors.grey;
const Color kInputFillColor = Color(0xFF2C2C2C);

class BuyerRegisterScreen extends StatefulWidget {
  const BuyerRegisterScreen({Key? key}) : super(key: key);

  @override
  State<BuyerRegisterScreen> createState() => _BuyerRegisterScreenState();
}

class _BuyerRegisterScreenState extends State<BuyerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = userCredential.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('buyers').doc(user.uid).set({
          'uid': user.uid,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'role': 'buyer',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration Successful!'), backgroundColor: kPrimaryColor));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const BuyerLoginScreen()));
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.message}'), backgroundColor: Colors.redAccent));
      }
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text('Create Account', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: kWhiteText), textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  const Text('Join BottleBack as a Buyer', style: TextStyle(fontSize: 16, color: kGreyText), textAlign: TextAlign.center),
                  const SizedBox(height: 40),

                  _buildTextField(controller: _nameController, label: 'Full Name', icon: Icons.person_rounded),
                  const SizedBox(height: 20),
                  _buildTextField(controller: _emailController, label: 'Email', icon: Icons.email_rounded, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 20),
                  _buildTextField(controller: _phoneController, label: 'Phone Number', icon: Icons.phone_rounded, keyboardType: TextInputType.phone),
                  const SizedBox(height: 20),
                  _buildTextField(controller: _passwordController, label: 'Password', icon: Icons.lock_rounded, isPassword: true, isObscure: _obscurePassword, toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword)),
                  const SizedBox(height: 20),
                  _buildTextField(controller: _confirmPasswordController, label: 'Confirm Password', icon: Icons.lock_outline_rounded, isPassword: true, isObscure: _obscureConfirmPassword, toggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)),
                  
                  const SizedBox(height: 40),

                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : const Text('Register', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                    ),
                  ),

                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already a member? ", style: TextStyle(color: kGreyText)),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const BuyerLoginScreen())),
                        child: const Text('Login', style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
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
    bool? isObscure,
    VoidCallback? toggleObscure,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? (isObscure ?? true) : false,
      keyboardType: keyboardType,
      style: const TextStyle(color: kWhiteText),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: kGreyText),
        prefixIcon: Icon(icon, color: kPrimaryColor),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(isObscure! ? Icons.visibility_off : Icons.visibility, color: kGreyText),
                onPressed: toggleObscure,
              )
            : null,
        filled: true,
        fillColor: kInputFillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: kPrimaryColor, width: 1.5)),
      ),
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
    );
  }
}