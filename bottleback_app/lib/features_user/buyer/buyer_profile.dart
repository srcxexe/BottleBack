import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/buyer_login.dart'; 

// --- Dark Theme Constants ---
const Color kBackgroundColor = Color(0xFF121212);
const Color kSurfaceColor = Color(0xFF1E1E1E);
const Color kPrimaryColor = Color(0xFF00BFA5);
const Color kWhiteText = Colors.white;

class BuyerProfileScreen extends StatefulWidget {
  const BuyerProfileScreen({Key? key}) : super(key: key);

  @override
  State<BuyerProfileScreen> createState() => _BuyerProfileScreenState();
}

class _BuyerProfileScreenState extends State<BuyerProfileScreen> {
  String _name = 'Loading...';
  String _email = 'Loading...';
  String _phone = 'Loading...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() { _name = 'Not Logged In'; _isLoading = false; });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('buyers').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        if (mounted) {
          setState(() {
            _name = data['name'] ?? 'Buyer';
            _email = user.email ?? 'N/A';
            _phone = data['phone'] ?? 'N/A';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() { _name = 'Error Loading Data'; _isLoading = false; });
    }
  }

  Future<void> _logout() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const BuyerLoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text('My Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kWhiteText)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: kSurfaceColor,
                    child: Icon(Icons.person, size: 60, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  Text(_name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kWhiteText)),
                  const SizedBox(height: 30),

                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: kSurfaceColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(label: 'Name', value: _name),
                        _buildDetailRow(label: 'Email', value: _email),
                        _buildDetailRow(label: 'Phone', value: _phone),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  _buildActionButton(
                    label: 'Logout',
                    icon: Icons.logout,
                    color: Colors.redAccent,
                    onPressed: _logout,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('$label:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey))),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kWhiteText), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildActionButton({required String label, required IconData icon, required Color color, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : onPressed,
        icon: Icon(icon, color: color),
        label: Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withOpacity(0.5), width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}