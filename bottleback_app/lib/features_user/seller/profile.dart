import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color kBackgroundColor = Color(0xFF121212);
const Color kSurfaceColor = Color(0xFF1E1E1E);
const Color kPrimaryColor = Color(0xFF00BFA5);
const Color kWhiteText = Colors.white;

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
          _name = data['name'] ?? '';
          _phone = data['phone'] ?? '';
          _bank = data['bank'] ?? '';
          _bankNo = data['bankNo'] ?? '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const CircleAvatar(
                radius: 50,
                backgroundColor: kSurfaceColor,
                child: Icon(Icons.person, size: 50, color: Colors.grey),
              ),
              const SizedBox(height: 15),
              Text(_name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kWhiteText)),
              const Text('Seller Account', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),

              _buildSectionHeader('Contact Info'),
              _buildInfoTile(Icons.phone_rounded, 'Phone', _phone),
              
              const SizedBox(height: 20),
              _buildSectionHeader('Bank Details'),
              _buildInfoTile(Icons.account_balance_rounded, 'Bank', _bank),
              _buildInfoTile(Icons.credit_card_rounded, 'Account No.', _bankNo),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: TextButton.icon(
                  onPressed: () => FirebaseAuth.instance.signOut().then((_) => Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false)),
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
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Align(alignment: Alignment.centerLeft, child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey))),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kSurfaceColor, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: kPrimaryColor, size: 20),
          const SizedBox(width: 15),
          Text(title, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: kWhiteText)),
        ],
      ),
    );
  }
}