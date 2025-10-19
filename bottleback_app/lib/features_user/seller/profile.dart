import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Constants (เพื่อใช้สีเดิม) ---
const Color kBackgroundColor = Color(0xFFB2F5E6);
const Color kPrimaryColor = Color(0xFF00BFA5);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'Loading...';
  String _phone = 'Loading...';
  String _bank = 'Loading...';
  String _bankNo = 'Loading...';
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
      final doc = await FirebaseFirestore.instance
          .collection('sellers')
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _name = data['name'] ?? 'User Name';
          _phone = data['phone'] ?? 'N/A';
          _bank = data['bank'] ?? 'N/A';
          _bankNo = data['bankNo'] ?? 'N/A';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ออกจากระบบ
  Future<void> _logout() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        // นำผู้ใช้กลับไปหน้าเลือก Role หรือหน้า Login
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/', // ให้แน่ใจว่าได้กำหนด root route ไปที่ RoleSelectScreen
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  // ฟังก์ชันจำลองสำหรับการแก้ไขโปรไฟล์ (สามารถสร้างหน้า EditProfileScreen ใหม่ได้)
  void _editProfile() {
    // ในการพัฒนาจริง ควร Navigator.push ไปยังหน้าแก้ไขโปรไฟล์
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Redirect to Edit Profile Screen... (Not implemented yet)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ส่วน Header (User Icon และ Name)
                    _buildProfileHeader(),
                    const SizedBox(height: 30),

                    // ส่วนข้อมูล Contact
                    _buildInfoCard(
                      title: 'Contact Information',
                      children: [
                        _buildInfoRow('Phone Number', _phone, Icons.phone_outlined),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ส่วนข้อมูล Bank
                    _buildInfoCard(
                      title: 'Bank Information',
                      children: [
                        _buildInfoRow('Bank Name', _bank, Icons.account_balance_outlined),
                        _buildInfoRow('Account Number', _bankNo, Icons.credit_card_outlined),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // ปุ่ม Edit Profile (สีดำตามดีไซน์)
                    _buildActionButton(
                      label: 'Edit Profile',
                      icon: Icons.edit_outlined,
                      color: Colors.black,
                      onPressed: _editProfile,
                    ),
                    const SizedBox(height: 16),

                    // ปุ่ม Logout (สีแดงตามดีไซน์)
                    _buildActionButton(
                      label: 'Logout',
                      icon: Icons.logout,
                      color: Colors.red,
                      onPressed: _logout,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Widget สำหรับส่วน Header (รูปโปรไฟล์และชื่อ)
  Widget _buildProfileHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: kPrimaryColor,
          child: const Icon(
            Icons.person,
            size: 50,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  // Widget สำหรับสร้าง Card ข้อมูล (Contact/Bank)
  Widget _buildInfoCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const Divider(height: 25, thickness: 1),
          ...children,
        ],
      ),
    );
  }

  // Widget สำหรับแสดงแต่ละแถวข้อมูลใน Card
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: kPrimaryColor),
          const SizedBox(width: 10),
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
                color: Colors.black,
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
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}