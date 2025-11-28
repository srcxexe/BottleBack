import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'request_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Light Theme Constants ---
const Color kBackgroundColor = Color(0xFFF5F5F5); 
const Color kSurfaceColor = Colors.white;          
const Color kPrimaryColor = Color(0xFF00796B);    
const Color kSecondaryColor = Color(0xFF80CBC4);  
const Color kBlackText = Colors.black87;           
const Color kGreyText = Colors.black54;            

class BuyerHomeScreen extends StatelessWidget {
  const BuyerHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ดึง ID ของผู้ใช้ปัจจุบัน
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('Please log in to view requests.', style: TextStyle(color: kBlackText)));
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text(
          'Sale Requests',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBlackText),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sale_requests') 
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
          }
          if (snapshot.hasError) {
            // แสดง Error แทนที่จะปล่อยให้แอป Crash
            return Center(child: Text('Something went wrong: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No sale requests found.', style: TextStyle(color: kGreyText)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final requestId = doc.id;

              final money = (data['totalMoney'] ?? 0.0) as num;
              final status = (data['status'] ?? 'Pending').toString(); // Ensure String
              final timestamp = data['timestamp'] as Timestamp?;
              final date = timestamp != null ? DateFormat('dd MMM, HH:mm').format(timestamp.toDate()) : '-';
              
              final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
              final weight = items.fold<double>(0.0, (sum, item) => sum + (item['weightKg'] as num? ?? 0.0).toDouble());
              
              final type = data['type'] ?? 'Standard Request';
              final isKiosk = type == 'Kiosk Deposit';

              // สีสถานะ
              Color statusColor = Colors.orange.shade700;
              Color statusBg = Colors.orange.withOpacity(0.1);
              IconData statusIcon = Icons.pending_actions_rounded;
              String statusText = status;

              if (status == 'Completed' || status == 'Paid') {
                statusColor = kPrimaryColor;
                statusBg = kPrimaryColor.withOpacity(0.1);
                statusIcon = Icons.check_circle_rounded;
              } else if (status == 'In Progress') {
                statusColor = Colors.blue.shade700;
                statusBg = Colors.blue.withOpacity(0.1);
                statusIcon = Icons.timeline_rounded;
              } else if (status == 'Rejected') {
                 statusColor = Colors.red.shade700;
                 statusBg = Colors.red.withOpacity(0.1);
                 statusIcon = Icons.cancel_rounded;
              }
              
              if (isKiosk) {
                statusIcon = Icons.recycling_rounded;
                statusText = 'Kiosk Deposit (Auto)';
              }

              // --- FIX: Safe Seller ID & Name Handling ---
              // แปลง sellerId เป็น String อย่างปลอดภัย (ป้องกันกรณีเป็น List/Int)
              final rawSellerId = data['sellerId'];
              final String sellerId = rawSellerId?.toString() ?? 'N/A';
              
              return FutureBuilder<DocumentSnapshot>(
                future: (sellerId != 'N/A') 
                    ? FirebaseFirestore.instance.collection('sellers').doc(sellerId).get()
                    : null,
                builder: (context, sellerSnapshot) {
                  // --- FIX: Safe Seller Name Handling ---
                  String sellerName = 'Loading...';
                  
                  if (sellerSnapshot.connectionState == ConnectionState.done) {
                    if (sellerSnapshot.hasData && sellerSnapshot.data!.exists) {
                       final sellerData = sellerSnapshot.data!.data() as Map<String, dynamic>?;
                       // ใช้ .toString() เพื่อป้องกัน Error ถ้า 'name' ถูกเก็บเป็น List หรือ Type อื่น
                       sellerName = sellerData?['name']?.toString() ?? 'Unknown Seller';
                    } else {
                       sellerName = 'Unknown Seller';
                    }
                  } else if (sellerId == 'N/A') {
                    sellerName = 'N/A';
                  }

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RequestDetailScreen(requestId: requestId)),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: kSurfaceColor, 
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(statusIcon, size: 28, color: statusColor),
                                  const SizedBox(width: 15),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'From $sellerName',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kBlackText),
                                      ),
                                      Text(date, style: const TextStyle(fontSize: 12, color: kGreyText)),
                                    ],
                                  ),
                                ],
                              ),
                              
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(color: Colors.black12, height: 1), 
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.scale, size: 16, color: kGreyText),
                              const SizedBox(width: 5),
                              Text(
                                'Weight: ${weight.toStringAsFixed(2)} kg',
                                style: const TextStyle(fontSize: 14, color: kGreyText),
                              ),
                              const Spacer(),
                              Text(
                                '฿${money.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_ios, size: 14, color: kGreyText),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}