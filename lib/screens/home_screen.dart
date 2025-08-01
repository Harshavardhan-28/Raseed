import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'warranties_screen.dart';
import "deals_screen.dart";
import "recurring_bills_screen.dart";
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'receipt_detail_screen.dart';
import '../widgets/family_invitation_handler.dart';
import '../widgets/shared_bottom_nav.dart';
import '../widgets/shared_floating_action_button.dart';
import '../widgets/shared_drawer.dart';

class HomeScreen extends StatefulWidget {
  final String? userName;
  const HomeScreen({super.key, this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<SmartWidget> _smartWidgets = [
    SmartWidget(
      title: 'Monthly Spend',
      amount: ' 2,847',
      subtitle: '12% less than last month',
      color: const Color(0xFF007AFF),
      icon: Icons.trending_down,
      isPositive: true,
    ),
    SmartWidget(
      title: 'Upcoming Warranties',
      amount: '3',
      subtitle: 'Expiring this month',
      color: const Color(0xFFFF9500),
      icon: Icons.shield_outlined,
      isPositive: false,
    ),
    SmartWidget(
      title: 'Deals For You',
      amount: '8',
      subtitle: 'Based on your spending',
      color: const Color(0xFF34C759),
      icon: Icons.local_offer_outlined,
      isPositive: true,
    ),
    SmartWidget(
      title: 'Recurring Bills',
      amount: ' 685',
      subtitle: 'Due this week',
      color: const Color(0xFFFF3B30),
      icon: Icons.refresh,
      isPositive: false,
    ),
  ];

  final List<RecentTransaction> _recentTransactions = [
    RecentTransaction(
      merchant: 'Starbucks Coffee',
      amount: '�12.45',
      category: 'Food & Dining',
      icon: Icons.local_cafe,
      time: '2 hours ago',
      color: const Color(0xFF8B4513),
    ),
    RecentTransaction(
      merchant: 'Amazon Prime',
      amount: ' 14.99',
      category: 'Subscriptions',
      icon: Icons.subscriptions,
      time: '1 day ago',
      color: const Color(0xFFFF9500),
    ),
    RecentTransaction(
      merchant: 'Shell Gas Station',
      amount: ' 45.60',
      category: 'Transportation',
      icon: Icons.local_gas_station,
      time: '2 days ago',
      color: const Color(0xFF007AFF),
    ),
    RecentTransaction(
      merchant: 'Whole Foods Market',
      amount: ' 89.23',
      category: 'Groceries',
      icon: Icons.shopping_cart,
      time: '3 days ago',
      color: const Color(0xFF34C759),
    ),
    RecentTransaction(
      merchant: 'Netflix',
      amount: ' 15.99',
      category: 'Entertainment',
      icon: Icons.movie,
      time: '5 days ago',
      color: const Color(0xFFE50914),
    ),
  ];

  void addReceipt(RecentTransaction transaction) {
    setState(() {
      _recentTransactions.insert(0, transaction);
    });
  }

  Widget _buildSmartWidgetCard(SmartWidget widget) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () => _handleSmartWidgetTap(widget),
        child: Card(
          elevation: 4,
          shadowColor: widget.color.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  widget.color.withOpacity(0.1),
                  widget.color.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(widget.icon, color: widget.color, size: 20),
                    Icon(
                      widget.isPositive
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: widget.isPositive ? Colors.green : Colors.orange,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.amount,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: widget.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.subtitle,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      drawer: const SharedDrawer(),
      body: _buildBody(),
      bottomNavigationBar: const SharedBottomNav(currentIndex: 0),
      floatingActionButton: const SharedFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Builder(
        builder:
            (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black87),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              widget.userName != null && widget.userName!.isNotEmpty
                  ? 'Welcome, ${widget.userName!}'
                  : 'Welcome',
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 18,
                overflow: TextOverflow.ellipsis,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.smart_toy, color: Color(0xFF8E44AD)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FamilyInvitationHandler(),
          _buildSmartWidgetsSection(),
          _buildRecentActivitySection(),
        ],
      ),
    );
  }

  Widget _buildSmartWidgetsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Smart Insights',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _smartWidgets.length,
            itemBuilder: (context, index) {
              return _buildSmartWidgetCard(_smartWidgets[index]);
            },
          ),
        ),
      ],
    );
  }

  void _handleSmartWidgetTap(SmartWidget widget) {
    if (widget.title == 'Upcoming Warranties') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const WarrantiesScreen()));
    } else if (widget.title == 'Deals For You') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const DealsScreen()));
    } else if (widget.title == 'Recurring Bills') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const RecurringBillsScreen()),
      );
    }
  }

  Widget _buildRecentActivitySection() {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        if (userId == null)
          const Center(child: Text('Please log in to view your receipts'))
        else
          StreamBuilder(
            stream:
                FirebaseFirestore.instance
                    .collection('receipts')
                    .where('user_id', isEqualTo: userId)
                    .orderBy('purchase_date', descending: true)
                    .limit(5)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No recent activity'));
              }
              final receipts = snapshot.data!.docs;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: receipts.length,
                itemBuilder: (context, index) {
                  final doc = receipts[index];
                  final data = doc.data();
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.receipt_long,
                          color: Colors.blue,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        data['store_name'] ?? 'Unknown Store',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        '${data['category'] ?? ''} • '
                        '${data['purchase_date'] != null ? (data['purchase_date'] as Timestamp).toDate().toLocal().toString().split(' ')[0] : ''}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
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
                            builder:
                                (context) =>
                                    ReceiptDetailScreen(receiptData: data),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        const SizedBox(height: 100), // Space for FAB
      ],
    );
  }
}

// Data Models
class SmartWidget {
  final String title;
  final String amount;
  final String subtitle;
  final Color color;
  final IconData icon;
  final bool isPositive;

  SmartWidget({
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.isPositive,
  });
}

class RecentTransaction {
  final String merchant;
  final String amount;
  final String category;
  final IconData icon;
  final String time;
  final Color color;

  RecentTransaction({
    required this.merchant,
    required this.amount,
    required this.category,
    required this.icon,
    required this.time,
    required this.color,
  });
}
