import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'buyer_register.dart'; 
import '../buyer/buyer_dashboard.dart'; 

// --- Dark Theme Constants ---
const Color kBackgroundColor = Color(0xFF121212);
const Color kSurfaceColor = Color(0xFF1E1E1E);
const Color kPrimaryColor = Color(0xFF00BFA5);
const Color kWhiteText = Colors.white;
const Color kGreyText = Colors.grey;
const Color kInputFillColor = Color(0xFF2C2C2C);

class BuyerLoginScreen extends StatefulWidget {
  const BuyerLoginScreen({Key? key}) : super(key: key);

  @override
  State<BuyerLoginScreen> createState() => _BuyerLoginScreenState();
}

class _BuyerLoginScreenState extends State<BuyerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true; 

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const BuyerDashboard()),
            (Route<dynamic> route) => false,
          );
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login Failed: ${e.message}'), backgroundColor: Colors.redAccent),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Icon Logo
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kSurfaceColor,
                      boxShadow: [BoxShadow(color: kPrimaryColor.withOpacity(0.2), blurRadius: 20)],
                    ),
                    child: const Icon(Icons.shopping_cart_rounded, size: 60, color: kPrimaryColor),
                  ),
                  const SizedBox(height: 30),

                  // Title
                  const Text(
                    'Welcome Back!',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: kWhiteText),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Login to continue as Buyer',
                    style: TextStyle(fontSize: 16, color: kGreyText),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 50),

                  // Email Field
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Password',
                    icon: Icons.lock_rounded,
                    isPassword: true,
                  ),
                  const SizedBox(height: 40),

                  // Login Button
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 5,
                        shadowColor: kPrimaryColor.withOpacity(0.4),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : const Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("New to BottleBack? ", style: TextStyle(color: kGreyText)),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BuyerRegisterScreen())),
                        child: const Text('Register now', style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
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
        fillColor: kInputFillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: kPrimaryColor, width: 1.5)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter $label';
        if (label == 'Email' && !value.contains('@')) return 'Invalid email';
        if (isPassword && value.length < 6) return 'Password too short';
        return null;
      },
    );
  }
}