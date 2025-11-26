import 'package:flutter/material.dart';

// --- Light Theme Constants ---
const Color kBackgroundColor = Color(0xFFF5F5F5); 
const Color kSurfaceColor = Colors.white;          
const Color kPrimaryColor = Color(0xFF00796B);    
const Color kBlackText = Colors.black87;           
const Color kGreyText = Colors.black54; 

class SuccessfulPaymentScreen extends StatelessWidget {
  const SuccessfulPaymentScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: kSurfaceColor, // White Circle
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: kPrimaryColor.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 5))],// Primary color glow
                ),
                child: const Icon(Icons.check_circle_outline, size: 100, color: kPrimaryColor), // Primary color icon
              ),
              const SizedBox(height: 40),
              const Text(
                'Payment Successful!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kBlackText), // Dark text
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Your payment slip has been uploaded. The seller will confirm the transaction shortly.',
                style: TextStyle(fontSize: 16, color: kGreyText), // Dark grey text
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate back to the Buyer Dashboard root
                    Navigator.of(context).popUntil((route) => route.isFirst); 
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor, // Primary color button
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('Back to Home', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)), // White text
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}