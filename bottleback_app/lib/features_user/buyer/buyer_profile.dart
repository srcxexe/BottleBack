import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../role_select.dart'; 

// --- Light Theme Constants ---
const Color kBackgroundColor = Color(0xFFF5F5F5); 
const Color kSurfaceColor = Colors.white;          
const Color kPrimaryColor = Color(0xFF00796B);    
const Color kBlackText = Colors.black87;           
const Color kGreyText = Colors.black54;            

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
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _name = data['name'] ?? 'N/A';
          _email = user.email ?? 'N/A';
          _phone = data['phone'] ?? 'N/A';
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() { _name = 'Data Missing'; _isLoading = false; });
      }
    } catch (e) {
      print("Error loading buyer data: $e");
      if (mounted) setState(() { _name = 'Error Loading'; _isLoading = false; });
    }
  }

  void _logout() async {
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
        title: const Text('Admin Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBlackText)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Header (Card)
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: kSurfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: kPrimaryColor.withOpacity(0.2),
                        child: Icon(Icons.business_center_rounded, size: 40, color: kPrimaryColor),
                      ),
                      const SizedBox(height: 15),
                      Text(_name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBlackText)),
                      const Text('Buyer/Admin', style: TextStyle(fontSize: 14, color: kGreyText)),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Details Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kSurfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(label: 'Email', value: _email),
                      const Divider(color: Colors.black12, height: 1),
                      _buildDetailRow(label: 'Phone', value: _phone),
                      const Divider(color: Colors.black12, height: 1),
                      _buildDetailRow(label: 'User ID', value: FirebaseAuth.instance.currentUser?.uid.substring(0, 8) ?? 'N/A'),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Logout Button
                _buildActionButton(
                  label: 'Logout',
                  icon: Icons.logout,
                  color: Colors.red.shade700,
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
          Expanded(flex: 2, child: Text('$label:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: kGreyText))),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kBlackText), textAlign: TextAlign.right)),
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
        ),
      ),
    );
  }
}