import 'package:flutter/material.dart';
import 'auth/seller_login.dart';
// **แก้ไขพาธให้ถูกต้อง:** อ้างอิงถึง buyer_dashboard.dart
// สมมติว่า role_select.dart อยู่ใน features_user/ และ buyer/ ก็อยู่ใน features_user/
import 'auth/buyer_login.dart'; // เพิ่มบรรทัดนี้
import 'buyer/buyer_dashboard.dart'; 

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          // ... (โค้ด Gradient Background) ...
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              const Color(0xFFB2F5E6).withOpacity(0.3),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Mascot Icon
                  const Icon(
                    Icons.recycling, 
                    size: 80,
                    color: Color(0xFF00BFA5),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // BottleBack Title
                  const Text(
                    'BottleBack',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 60),
                  
                  // Seller Button (นำทางไปหน้า Login)
                  SizedBox(
                    width: double.infinity,
                    height: 100,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SellerLoginScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: const BorderSide(color: Color(0xFF00BFA5), width: 3),
                        ),
                        elevation: 10,
                        shadowColor: const Color(0xFF00BFA5).withOpacity(0.5),
                      ),
                      child: const Text(
                        'Seller',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00BFA5),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Buyer Button (ใช้ InkWell และ onTap นำทางไป BuyerDashboard)
                  SizedBox(
                    width: double.infinity,
                    height: 100,
                    child: InkWell(
                      onTap: () {
                        // **นำทางไปยัง BuyerDashboard ทันที**
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BuyerLoginScreen(), 
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(15), 
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00BFA5), 
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00BFA5).withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Buyer',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 80),
                  
                  // Decorative circles
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB2F5E6).withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// CustomPainter code 
class LeafVeinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width * 0.5, 0);
    path.lineTo(size.width * 0.5, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}