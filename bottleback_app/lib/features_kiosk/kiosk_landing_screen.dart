import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'kiosk_main_screen.dart';
import 'kiosk_login_screen.dart';

// --- Theme Constants ---
const Color kBackgroundColor = Color(0xFFF5F5F5);
const Color kPrimaryColor = Color(0xFF00796B);
const Color kBlackText = Colors.black87;

class KioskLandingScreen extends StatelessWidget {
  const KioskLandingScreen({super.key});

  void _handleStart(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const KioskMainScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const KioskLoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: InkWell(
        onTap: () => _handleStart(context),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryColor.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 10,
                    )
                  ],
                ),
                child: const Icon(Icons.recycling, size: 100, color: kPrimaryColor),
              ),
              const SizedBox(height: 50),
              const Text(
                'Welcome to BottleBack Kiosk',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: kBlackText,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Touch anywhere to start recycling',
                style: TextStyle(
                  fontSize: 18,
                  color: kBlackText.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 80),
              SizedBox(
                width: size.width * 0.4,
                height: 70,
                child: ElevatedButton.icon(
                  onPressed: () => _handleStart(context),
                  icon: const Icon(Icons.touch_app, color: Colors.white, size: 30),
                  label: const Text(
                    'START',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}