import 'package:flutter/material.dart';

// --- Theme Constants (เพื่อให้ใช้สไตล์เดียวกัน) ---
const Color kPrimaryColor = Color(0xFF00796B);
const Color kBlackText = Colors.black87;

/// Custom Dialog สำหรับแจ้งเตือนให้เอาฝาขวดออก
class BottleCapAlertDialog extends StatelessWidget {
  const BottleCapAlertDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 30),
          SizedBox(width: 10),
          Text('CAP DETECTED!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Please remove the water bottle cap.',
            style: TextStyle(fontSize: 18, color: kBlackText),
          ),
          SizedBox(height: 15),
          Text(
            '',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text('OK', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
    );
  }
}