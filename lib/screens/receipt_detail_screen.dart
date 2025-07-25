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
        foregroundColor: const Color(0xFF202124),
        titleTextStyle: const TextStyle(
          color: Color(0xFF202124),
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5F6368)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Header Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4285F4), Color(0xFF1A73E8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4285F4).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    receiptData['store_name'] ?? 'Store Name',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  if (receiptData['parsed_receipt_no'] != null &&
                      receiptData['parsed_receipt_no'].toString().toLowerCase() != 'null')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Text(
                        'Receipt #${receiptData['parsed_receipt_no']}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ),
                ],
              ),
            ),
            
            // Receipt Details Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8EAED), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outlined, color: Color(0xFF4285F4), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Receipt Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF202124),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildDetailRow(Icons.category_outlined, 'Category', receiptData['category']),
                    _buildDetailRow(Icons.calendar_today_outlined, 'Purchase Date', _formatDate(receiptData['purchase_date'])),
                    _buildDetailRow(Icons.attach_money_outlined, 'Currency', receiptData['currency']),
                    _buildDetailRow(Icons.receipt_outlined, 'Tax Amount', receiptData['tax_amount']),
                    _buildDetailRow(Icons.account_balance_wallet_outlined, 'Total Amount', receiptData['total_amount'], isHighlighted: true),
                  ],
                ),
              ),
            ),
            
            // Line Items Section
            if (receiptData['line_items'] != null && receiptData['line_items'] is List && (receiptData['line_items'] as List).isNotEmpty)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8EAED), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shopping_cart_outlined, color: Color(0xFF4285F4), size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Items Purchased',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF202124),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F0FE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${(receiptData['line_items'] as List).length} items',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1A73E8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ...List.generate((receiptData['line_items'] as List).length, (idx) {
                        final item = (receiptData['line_items'] as List)[idx] as Map<String, dynamic>;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFBFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE8EAED)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F0FE),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Color(0xFF1A73E8),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['description'] ?? item['name'] ?? 'Item',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF202124),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          'Qty: ${item['quantity'] ?? '-'}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF5F6368),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          'Price: ${item['price'] ?? '-'}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF137333),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (item['category'] != null && item['category'].toString().isNotEmpty)
                                      Container(
                                        margin: const EdgeInsets.only(top: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F0FE),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          item['category'],
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF1A73E8),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 100), // Extra space at bottom
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, dynamic value, {bool isHighlighted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE8EAED),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isHighlighted 
                ? const Color(0xFFE6F4EA)
                : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isHighlighted 
                ? const Color(0xFF137333) 
                : const Color(0xFF4285F4),
              size: 16,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF5F6368),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value?.toString() ?? '-',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400,
                    color: isHighlighted 
                      ? const Color(0xFF137333)
                      : const Color(0xFF202124),
                  ),
                ),
              ],
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

