import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'item_details_screen.dart';

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
        foregroundColor: const Color(0xFF202124),
        titleTextStyle: const TextStyle(
          color: Color(0xFF202124),
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body:
          userId == null
              ? const Center(
                child: Text('Please log in to view your inventory'),
              )
              : StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('line_items')
                        .where('user_id', isEqualTo: userId)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No inventory items found'),
                    );
                  }
                  final items = snapshot.data!.docs;
                  // Group items by category
                  final Map<String, List<QueryDocumentSnapshot>> grouped = {};
                  for (var doc in items) {
                    final data = doc.data() as Map<String, dynamic>;
                    final category = data['category'] ?? 'Uncategorized';
                    grouped.putIfAbsent(category, () => []).add(doc);
                  }
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children:
                        grouped.entries.map((entry) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              ...entry.value.map((doc) {
                                final item = doc.data() as Map<String, dynamic>;
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF64B5F6,
                                        ).withOpacity(0.1),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => ItemDetailsScreen(
                                                documentId: doc.id,
                                              ),
                                        ),
                                      );
                                    },
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 8,
                                    ),
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF64B5F6),
                                            Color(0xFF42A5F5),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.inventory_2_outlined,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      item['description'] ??
                                          item['name'] ??
                                          'Item',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Qty: ${item['quantity'] ?? '-'} | Price: ${item['price'] ?? '-'}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF64B5F6,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        item['purchase_date'] != null
                                            ? _formatDate(item['purchase_date'])
                                            : '',
                                        style: const TextStyle(
                                          color: Color(0xFF64B5F6),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
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
    if (value is Timestamp) {
      return value.toDate().toLocal().toString().split(' ')[0];
    }
    return value.toString();
  }
}
