import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        child: SizedBox(
          height: 500, // Adjust height as needed for your design
          child: ListView(
            children: [
              _buildDetailRow('Store Name', receiptData['store_name']),
              _buildDetailRow('Receipt No', receiptData['receipt_no']),
              _buildDetailRow('Category', receiptData['category']),
              _buildDetailRow('Purchase Date', _formatDate(receiptData['purchase_date'])),
              _buildDetailRow('Currency', receiptData['currency']),
              _buildDetailRow('Tax Amount', receiptData['tax_amount']),
              _buildDetailRow('Total Amount', receiptData['total_amount']),
              _buildDetailRow('User ID', receiptData['user_id']),
              const SizedBox(height: 16),
              if (receiptData['line_items'] != null && receiptData['line_items'] is List && (receiptData['line_items'] as List).isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Line Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ...List.generate((receiptData['line_items'] as List).length, (idx) {
                      final item = (receiptData['line_items'] as List)[idx] as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(item['description'] ?? item['name'] ?? 'Item'),
                          subtitle: Text('Qty: ${item['quantity'] ?? '-'} | Price: ${item['price'] ?? '-'}'),
                          trailing: Text(item['category'] ?? ''),
                        ),
                      );
                    }),
                  ],
                ),
            ],
          ),
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

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    if (value is String) return value;
    if (value is DateTime) return value.toLocal().toString().split(' ')[0];
    if (value is Timestamp) return value.toDate().toLocal().toString().split(' ')[0];
    return value.toString();
  }
}
