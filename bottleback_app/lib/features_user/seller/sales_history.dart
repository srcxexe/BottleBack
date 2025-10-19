// ในไฟล์ sales_history.dart
import 'package:flutter/material.dart';

class SalesHistoryScreen extends StatelessWidget {
  const SalesHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB2F5E6),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        title: const Text(
          'Sales History',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          
        ),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text(
          'Sales History Page',
          style: TextStyle(fontSize: 20, color: Colors.black),
        ),
      ),
    );
  }
}