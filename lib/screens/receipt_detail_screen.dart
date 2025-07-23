import 'package:flutter/material.dart';

class ReceiptDetailScreen extends StatelessWidget {
  final Map<String, dynamic> receiptData;
  const ReceiptDetailScreen({super.key, required this.receiptData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Details'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            _buildDetailRow('Store Name', receiptData['store_name']),
            _buildDetailRow('Receipt No', receiptData['receipt_no']),
            _buildDetailRow('Category', receiptData['category']),
            _buildDetailRow('Date & Time', receiptData['date_and_time']),
            _buildDetailRow('Currency', receiptData['currency']),
            _buildDetailRow('Tax Amount', receiptData['tax_amount']),
            _buildDetailRow('Total Amount', receiptData['total_amount']),
            _buildDetailRow('User ID', receiptData['user_id']),
            // Add more fields as needed
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value?.toString() ?? '-',
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
