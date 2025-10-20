import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// **สำคัญ:** แก้ไขพาธนี้ให้ชี้ไปยัง buyer_login.dart ที่ถูกต้อง
import '../auth/buyer_login.dart'; 

// --- Constants (ใช้สีเดียวกับ Dashboard) ---
const Color kBackgroundColor = Color(0xFFB2F5E6); 
const Color kPrimaryColor = Color(0xFF00BFA5); 
const Color kDarkTextColor = Colors.black87;

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

  // ดึงข้อมูลผู้ใช้ปัจจุบันจาก Firestore
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _name = 'Not Logged In';
          _isLoading = false;
        });
      }
      return;
    }

    try {
      // ดึงข้อมูลจาก Collection 'buyers'
      final doc = await FirebaseFirestore.instance
          .collection('buyers')
          .doc(user.uid)
          .get();
      
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
      if (mounted) {
        setState(() {
          _name = 'Error Loading Data';
          _isLoading = false;
        });
      }
    }
  }

  // *** ฟังก์ชันสำหรับ Logout ***
  Future<void> _logout() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signOut();
      
      // นำทางกลับไปหน้า BuyerLoginScreen และล้าง Stack ทั้งหมด
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const BuyerLoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
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
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: kDarkTextColor,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Icon/Avatar
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: kPrimaryColor,
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kDarkTextColor),
                  ),
                  const SizedBox(height: 30),

                  // Profile Details Card
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(label: 'Name', value: _name),
                        _buildDetailRow(label: 'Email', value: _email),
                        _buildDetailRow(label: 'Phone', value: _phone),
                        // ... เพิ่มรายละเอียดอื่นๆ ของ Buyer ได้ที่นี่
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // *** ปุ่ม Logout ***
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

  // Widget สำหรับแสดงรายละเอียดแต่ละแถว
  Widget _buildDetailRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kDarkTextColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // Widget สำหรับปุ่ม Action (Edit/Logout)
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : onPressed,
        icon: Icon(icon, color: color),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}