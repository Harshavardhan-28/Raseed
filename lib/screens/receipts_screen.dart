import 'package:flutter/material.dart';
import 'home_screen.dart';

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
    // For demo, use the same _recentTransactions as HomeScreen
    // In a real app, this would come from a provider or database
    final List<RecentTransaction> receipts = [
      RecentTransaction(
        merchant: 'Starbucks Coffee',
        amount: '\$12.45',
        category: 'Food & Dining',
        icon: Icons.local_cafe,
        time: '2 hours ago',
        color: const Color(0xFF8B4513),
      ),
      RecentTransaction(
        merchant: 'Amazon Prime',
        amount: '\$14.99',
        category: 'Subscriptions',
        icon: Icons.subscriptions,
        time: '1 day ago',
        color: const Color(0xFFFF9500),
      ),
      RecentTransaction(
        merchant: 'Shell Gas Station',
        amount: '\$45.60',
        category: 'Transportation',
        icon: Icons.local_gas_station,
        time: '2 days ago',
        color: const Color(0xFF007AFF),
      ),
      RecentTransaction(
        merchant: 'Whole Foods Market',
        amount: '\$89.23',
        category: 'Groceries',
        icon: Icons.shopping_cart,
        time: '3 days ago',
        color: const Color(0xFF34C759),
      ),
      RecentTransaction(
        merchant: 'Netflix',
        amount: '\$15.99',
        category: 'Entertainment',
        icon: Icons.movie,
        time: '5 days ago',
        color: const Color(0xFFE50914),
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: receipts.length,
      itemBuilder: (context, index) {
        final receipt = receipts[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: receipt.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(receipt.icon, color: receipt.color, size: 24),
            ),
            title: Text(
              receipt.merchant,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            subtitle: Text(
              '${receipt.category} • ${receipt.time}',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            trailing: Text(
              receipt.amount,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            onTap: () {
              // TODO: Navigate to receipt detail screen
            },
          ),
        );
      },
    );
  }
}
