import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../role_select.dart'; // ใช้ RoleSelectScreen หลัง Sign Out

// --- Light Theme Constants ---
const Color kBackgroundColor = Color(0xFFF5F5F5); 
const Color kSurfaceColor = Colors.white;          
const Color kPrimaryColor = Color(0xFF00796B);    
const Color kBlackText = Colors.black87;           
const Color kGreyText = Colors.black54;            

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '...';
  String _phone = '...';
  String _bank = '...';
  String _bankNo = '...';
  String _walletBalance = '0.00';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('sellers').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _name = data['name'] ?? 'N/A';
          _phone = data['phone'] ?? 'N/A';
          _bank = data['bank'] ?? 'N/A';
          _bankNo = data['bankNo'] ?? 'N/A';
          final balance = (data['walletBalance'] ?? 0.0) as num;
          _walletBalance = balance.toStringAsFixed(2);
          _isLoading = false;
        });
      }
    } else {
      setState(() => _isLoading = false);
    }
  }
  
  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const RoleSelectScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text('Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBlackText)),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header (Balance)
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: kPrimaryColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: kPrimaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Column(
                    children: [
                      const Text('Current Wallet Balance', style: TextStyle(fontSize: 18, color: Colors.white70)),
                      const SizedBox(height: 5),
                      Text('฿$_walletBalance', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(height: 10),
                      Text('User ID: ${FirebaseAuth.instance.currentUser?.uid.substring(0, 8) ?? 'N/A'}', style: const TextStyle(fontSize: 12, color: Colors.white54)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),

                // Personal Info Section
                _buildSectionHeader('Personal Information'),
                _buildInfoTile(Icons.person_rounded, 'Full Name', _name),
                _buildInfoTile(Icons.phone_rounded, 'Phone Number', _phone),
                
                const SizedBox(height: 20),

                // Bank Info Section
                _buildSectionHeader('Bank Account'),
                _buildInfoTile(Icons.account_balance_rounded, 'Bank Name', _bank),
                _buildInfoTile(Icons.credit_card_rounded, 'Account Number', _bankNo),

                const SizedBox(height: 40),
                
                // Sign Out Button
                SizedBox(
                  height: 50,
                  child: TextButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                    label: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                )
              ],
            ),
          ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Align(alignment: Alignment.centerLeft, child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kGreyText))), // สีเทาเข้ม
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurfaceColor, // พื้นผิวสว่าง
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(icon, color: kPrimaryColor, size: 20),
          const SizedBox(width: 15),
          Text(title, style: const TextStyle(color: kGreyText)), // สีเทาเข้ม
          const Spacer(),
          Text(value, style: const TextStyle(color: kBlackText, fontWeight: FontWeight.w600)), // สีดำ
        ],
      ),
    );
  }
}