import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// **ต้องมีไฟล์ BuyerRegisterScreen.dart อยู่ในโฟลเดอร์เดียวกัน**
import 'buyer_register.dart'; 
import '../buyer/buyer_dashboard.dart'; 

// --- Constants (ใช้สีเดียวกันกับโปรเจกต์) ---
const Color kPrimaryColor = Color(0xFF00BFA5); 
const Color kBackgroundColor = Color(0xFFB2F5E6); 
const Color kDarkTextColor = Colors.black87;

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
  // **ส่วนที่เพิ่มเข้ามา:** สำหรับควบคุมการแสดง/ซ่อนรหัสผ่าน
  bool _obscurePassword = true; 

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });
      try {
        // *** โค้ดจริงสำหรับการล็อกอินด้วย Firebase ***
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (mounted) {
          // หากล็อกอินสำเร็จ ให้นำทางไปยัง BuyerDashboard
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const BuyerDashboard()),
            (Route<dynamic> route) => false,
          );
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login Failed: ${e.message ?? "Unknown error"}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
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
      // ใช้ Container ที่มี Gradient Background เหมือน RoleSelect/Seller Login
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              kBackgroundColor.withOpacity(0.3),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Icon
                    const Icon(
                      Icons.shopping_cart_outlined, 
                      size: 80,
                      color: kPrimaryColor,
                    ),
                    const SizedBox(height: 10),

                    // Title
                    const Text(
                      'Buyer Login',
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: kDarkTextColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 50),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _buildInputDecoration('Email', Icons.email),
                      validator: (value) {
                        if (value == null || value.isEmpty || !value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      // **ใช้ _obscurePassword และเพิ่ม suffixIcon**
                      obscureText: _obscurePassword,
                      decoration: _buildInputDecoration('Password', Icons.lock).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: kPrimaryColor.withOpacity(0.7),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),

                    // Login Button
                    SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 10,
                          shadowColor: kPrimaryColor.withOpacity(0.5),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // **ลิงก์ลงทะเบียน (ปรับให้เหมือน Seller Login)**
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "If you're new to BottleBack, ",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            // นำทางไปหน้า Buyer Register
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const BuyerRegisterScreen(), 
                              ),
                            );
                          },
                          child: const Text(
                            'register now',
                            style: TextStyle(
                              fontSize: 14,
                              color: kPrimaryColor, 
                              fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: kPrimaryColor.withOpacity(0.7)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: kPrimaryColor.withOpacity(0.2), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: kPrimaryColor, width: 2),
      ),
      labelStyle: const TextStyle(color: Colors.black54),
    );
  }
}