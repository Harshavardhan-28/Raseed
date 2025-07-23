import 'package:flutter/material.dart';

class DealsScreen extends StatelessWidget {
  const DealsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Deals For You', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_outlined, size: 64, color: Color(0xFF34C759)),
            const SizedBox(height: 24),
            const Text('Personalized deals will appear here soon!', style: TextStyle(fontSize: 18, color: Colors.black87)),
            const SizedBox(height: 8),
            const Text('Check back for offers based on your spending.', style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
