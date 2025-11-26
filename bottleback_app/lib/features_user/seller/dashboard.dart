import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bottle_count.dart'; 
import 'sales_history.dart'; 
import 'profile.dart'; 

// --- Light Theme Constants ---
const Color kBackgroundColor = Color(0xFFF5F5F5); // พื้นหลังสว่างมาก (เกือบขาว)
const Color kSurfaceColor = Colors.white;          // สี Card, Nav Bar (ขาว)
const Color kPrimaryColor = Color(0xFF00796B);    // สีเขียวเข้ม (Dark Teal)
const Color kSecondaryColor = Color(0xFF80CBC4);  // สีเขียวอ่อน (Light Teal)
const Color kBlackText = Colors.black87;           // สีตัวอักษรเข้ม
const Color kGreyText = Colors.black54;            // สีตัวอักษรรอง

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({Key? key}) : super(key: key);

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  int _currentIndex = 0;
  
  late final List<Widget> _screens = [
    const DashboardHome(),
    const BottleCountScreen(),
    const SalesHistoryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor, // Light background
      body: _screens[_currentIndex], 
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: kSurfaceColor, // Nav Bar background white
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, -2))], // Subtle shadow
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: kPrimaryColor,
          unselectedItemColor: kGreyText, // Darker grey for light theme
          backgroundColor: kSurfaceColor,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.space_dashboard_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_rounded), label: 'Count'),
            BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class DashboardHome extends StatefulWidget {
  const DashboardHome({Key? key}) : super(key: key);

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  String _userName = 'User';
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
        setState(() {
          _userName = doc.data()?['name'] ?? 'User';
          _isLoading = false;
        });
      } else if (mounted) setState(() => _isLoading = false);
    } else if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _showConfirmSaleDialog(double totalMoney) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final sellerDoc = await FirebaseFirestore.instance.collection('sellers').doc(user.uid).get();
    final data = sellerDoc.data() as Map<String, dynamic>;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: kSurfaceColor, // Dialog สีขาว
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Confirm Sale Request', style: TextStyle(fontWeight: FontWeight.bold, color: kBlackText)), // Dark text
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1), // Light background
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: kPrimaryColor.withOpacity(0.5))
                ),
                child: Text(
                  '฿ ${totalMoney.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kPrimaryColor),
                ),
              ),
              const SizedBox(height: 15),
              Text('Sending this request will reset your current inventory to zero.', textAlign: TextAlign.center, style: TextStyle(color: kGreyText)), // Dark grey text
            ],
          ),
          actionsPadding: const EdgeInsets.all(20),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: kGreyText)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              onPressed: () async {
                // ... Logic เดิม ...
                final profileData = sellerDoc.data() as Map<String, dynamic>;
                final Map<String, dynamic> requestData = {
                  'sellerId': user.uid,
                  'totalMoney': totalMoney,
                  'totalWeight': data['totalWeight'] ?? 0.0,
                  'petCount': data['petCount'] ?? 0,
                  'hdpeCount': data['hdpeCount'] ?? 0,
                  'canCount': data['canCount'] ?? 0,
                  'petWeight': data['petWeight'] ?? 0.0,
                  'hdpeWeight': data['hdpeWeight'] ?? 0.0,
                  'canWeight': data['canWeight'] ?? 0.0,
                  'breakdown': [ 
                     if ((data['petCount'] ?? 0) > 0) {'bottleType': 'PET', 'count': data['petCount'], 'weight': data['petWeight'], 'money': (data['petWeight']*5.0)},
                     if ((data['hdpeCount'] ?? 0) > 0) {'bottleType': 'HDPE', 'count': data['hdpeCount'], 'weight': data['hdpeWeight'], 'money': (data['hdpeWeight']*3.0)},
                     if ((data['canCount'] ?? 0) > 0) {'bottleType': 'Can', 'count': data['canCount'], 'weight': data['canWeight'], 'money': (data['canWeight']*10.0)},
                  ],
                  'status': 'Pending',
                  'timestamp': FieldValue.serverTimestamp(),
                  'sellerName': profileData['name'] ?? 'N/A',
                  'sellerPhone': profileData['phone'] ?? 'N/A',
                  'sellerBank': profileData['bank'] ?? 'N/A',
                  'sellerBankNo': profileData['bankNo'] ?? 'N/A',
                };
                await FirebaseFirestore.instance.collection('sale_requests').add(requestData);
                await FirebaseFirestore.instance.collection('sellers').doc(user.uid).update({
                  'totalWeight': 0.0, 'totalMoney': 0.0,
                  'petCount': 0, 'hdpeCount': 0, 'canCount': 0,
                  'petWeight': 0.0, 'hdpeWeight': 0.0, 'canWeight': 0.0,
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Success! Request sent.'), backgroundColor: kPrimaryColor));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor, // Primary color button
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
              ),
              child: const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), // White text on dark teal
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _isLoading) return const Center(child: CircularProgressIndicator(color: kPrimaryColor));

    return Scaffold(
      backgroundColor: kBackgroundColor, // Light background
      body: SafeArea( 
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('sellers').doc(user.uid).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
            if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text('No Data Found', style: TextStyle(color: kBlackText))); 
            
            final data = snapshot.data!.data() as Map<String, dynamic>;
            final totalWeight = (data['totalWeight'] ?? 0.0).toDouble();
            final totalMoney = (data['totalMoney'] ?? 0.0).toDouble();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome back,', style: TextStyle(fontSize: 16, color: kGreyText)), 
                          Text(_userName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBlackText)), 
                        ],
                      ),
                      CircleAvatar(radius: 24, backgroundColor: kSecondaryColor.withOpacity(0.3), child: Icon(Icons.person, color: kPrimaryColor)), 
                    ],
                  ),
                  const SizedBox(height: 30),
                  _buildSummaryBox(totalMoney, totalWeight),
                  const SizedBox(height: 25),
                  Text('Current Inventory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBlackText)), 
                  const SizedBox(height: 15),
                  _buildInventoryList(data),
                  const SizedBox(height: 30),
                  _buildConfirmSaleButton(totalMoney),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryBox(double totalMoney, double totalWeight) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: kPrimaryColor, // Solid Primary color background
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: kPrimaryColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Estimated Value', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 5),
          Text('฿ ${totalMoney.toStringAsFixed(2)}', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)), // White text
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)), // Light background
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.scale_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Total Weight: ${totalWeight.toStringAsFixed(2)} kg', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryList(Map<String, dynamic> data) {
    return Column(
      children: [
        _buildInventoryItem('PET Bottles', data['petCount']??0, Icons.water_drop_rounded, Colors.blue), 
        _buildInventoryItem('HDPE Bottles', data['hdpeCount']??0, Icons.recycling_rounded, Colors.green),
        _buildInventoryItem('Aluminum Cans', data['canCount']??0, Icons.sports_bar_rounded, Colors.deepOrange),
      ],
    );
  }

  Widget _buildInventoryItem(String title, int count, IconData icon, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurfaceColor, // White card
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] // Subtle shadow
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: kBlackText)), // Dark text
          ),
          Text('$count units', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kPrimaryColor)), // Primary color number
        ],
      ),
    );
  }

  Widget _buildConfirmSaleButton(double totalMoney) {
    bool isEnabled = totalMoney > 0;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isEnabled ? () => _showConfirmSaleDialog(totalMoney) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor, // Dark Teal button
          foregroundColor: Colors.white, // White text
          elevation: isEnabled ? 5 : 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('Confirm Sale Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(width: 10),
            Icon(Icons.arrow_forward_rounded),
          ],
        ),
      ),
    );
  }
}