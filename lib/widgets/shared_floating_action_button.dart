import 'package:flutter/material.dart';
import '../screens/receipt_entry_screen.dart';

class SharedFloatingActionButton extends StatelessWidget {
  const SharedFloatingActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: const Color(0xFF007AFF),
      elevation: 4.0,
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ReceiptEntryScreen()),
        );
      },
      child: const Icon(Icons.add, color: Colors.white, size: 28),
    );
  }
}
