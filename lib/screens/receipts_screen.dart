import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'receipt_detail_screen.dart';

class ReceiptsScreen extends StatelessWidget {
  const ReceiptsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Receipts'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: _buildReceiptsList(context),
      backgroundColor: const Color(0xFFF8F9FA),
    );
  }

  Widget _buildReceiptsList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('receipts').orderBy('date_and_time', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No receipts found'));
        }
        final receipts = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: receipts.length,
          itemBuilder: (context, index) {
            final doc = receipts[index];
            final data = doc.data() as Map<String, dynamic>;
            return Card(
              elevation: 1,
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long, color: Colors.blue, size: 24),
                ),
                title: Text(
                  data['store_name'] ?? 'Unknown Store',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                subtitle: Text(
                  '${data['category'] ?? ''} • ${data['date_and_time'] ?? ''}',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                trailing: Text(
                  '${data['currency'] ?? ''} ${data['total_amount'] ?? ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReceiptDetailScreen(receiptData: data),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
