import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import '../auth/buyer_login.dart'; // Comment out local import if path is unknown

// --- Light Theme Constants ---
const Color kBackgroundColor = Color(0xFFF5F5F5); 
const Color kSurfaceColor = Colors.white;          
const Color kPrimaryColor = Color(0xFF00796B);    
const Color kSecondaryColor = Color(0xFF80CBC4);  
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
          _email = data['email'] ?? user.email ?? 'N/A';
          _phone = data['phone'] ?? 'N/A';
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() { _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _logout() {
    FirebaseAuth.instance.signOut().then((_) {
      // Assuming the login route is '/', navigating back to it.
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false); 
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor, // Light background
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text('Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBlackText)), // Dark text
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: kSecondaryColor.withOpacity(0.3),
                    child: Icon(Icons.business_rounded, size: 50, color: kPrimaryColor), // Use a business/buyer icon
                  ),
                  const SizedBox(height: 15),
                  Text(_name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBlackText)), // Dark text
                  Text('Buyer Account', style: TextStyle(color: kGreyText)), // Dark grey text
                  const SizedBox(height: 40),

                  // Detail Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: kSurfaceColor, // White card
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
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
                    icon: Icons.logout_rounded,
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
          Expanded(flex: 2, child: Text('$label:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: kGreyText))), // Dark grey text
          Expanded(flex: 3, child: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kBlackText), textAlign: TextAlign.right)), // Dark text
        ],
      ),
    );
  }

  Widget _buildActionButton({required String label, required IconData icon, required Color color, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color, // Solid color for better visibility in light theme
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }
}