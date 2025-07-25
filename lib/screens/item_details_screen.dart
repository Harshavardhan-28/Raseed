import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'warranty_receipt_entry_screen.dart';

class ItemDetailsScreen extends StatelessWidget {
  final String documentId;

  const ItemDetailsScreen({super.key, required this.documentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
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
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance
                .collection('line_items')
                .doc(documentId)
                .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Item not found'));
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final itemName = data['description'] ?? data['name'] ?? 'Item';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF64B5F6), Color(0xFF42A5F5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.inventory_2,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        itemName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: Color(0xFF202124),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, color: Colors.black12),
                const SizedBox(height: 16),
                _detailCard(
                  children: [
                    _detailRow('Category', data['category'] ?? 'Uncategorized'),
                    _detailRow('Quantity', data['quantity']?.toString() ?? '-'),
                    _detailRow(
                      'Price',
                      'SAR ${data['price']?.toStringAsFixed(2) ?? '-'}',
                    ),
                    _detailRow(
                      'Purchase Date',
                      _formatDate(data['purchase_date']),
                    ),
                    if (data['notes'] != null && data['notes'].isNotEmpty)
                      _detailRow('Notes', data['notes']),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.receipt_long),
                        label: const Text(
                          'Add Warranty Receipt',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF42A5F5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => WarrantyReceiptEntryScreen(
                                    itemId: documentId,
                                  ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _detailCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64B5F6).withOpacity(0.1),
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
      child: Column(children: children),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Color(0xFF202124),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
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
    if (value is Timestamp) {
      return value.toDate().toLocal().toString().split(' ')[0];
    }
    return value.toString();
  }
}
