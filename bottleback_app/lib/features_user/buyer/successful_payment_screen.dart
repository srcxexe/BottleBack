import 'package:flutter/material.dart';

// --- Dark Theme Constants ---
const Color kBackgroundColor = Color(0xFF121212);
const Color kSurfaceColor = Color(0xFF1E1E1E);
const Color kPrimaryColor = Color(0xFF00BFA5);
const Color kWhiteText = Colors.white;

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
                  color: kSurfaceColor,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: kPrimaryColor.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 5))],
                ),
                child: Icon(Icons.check_circle_outline, size: 100, color: kPrimaryColor),
              ),
              const SizedBox(height: 40),
              const Text(
                'Payment Successful!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kWhiteText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Your payment slip has been uploaded. The seller will confirm the transaction shortly.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst); 
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('Back to Home', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}