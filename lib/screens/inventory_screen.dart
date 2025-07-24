import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
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
      body: userId == null
          ? const Center(child: Text('Please log in to view your inventory'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('line_items')
                  .where('user_id', isEqualTo: userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No inventory items found'));
                }
                final items = snapshot.data!.docs;
                // Group items by category
                final Map<String, List<Map<String, dynamic>>> grouped = {};
                for (var doc in items) {
                  final data = doc.data() as Map<String, dynamic>;
                  final category = data['category'] ?? 'Uncategorized';
                  grouped.putIfAbsent(category, () => []).add(data);
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: grouped.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                ...entry.value.map((item) => Card(
                      elevation: 1,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(item['description'] ?? item['name'] ?? 'Item'),
                        subtitle: Text('Qty: ${item['quantity'] ?? '-'} | Price: ${item['price'] ?? '-'}'),
                        trailing: Text(item['purchase_date'] != null ? _formatDate(item['purchase_date']) : ''),
                      ),
                    )),
                        const SizedBox(height: 16),
                      ],
                    );
                  }).toList(),
                );
              },
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
