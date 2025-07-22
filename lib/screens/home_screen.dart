import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'warranties_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? userName;
  const HomeScreen({super.key, this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<SmartWidget> _smartWidgets = [
    SmartWidget(
      title: 'Monthly Spend',
      amount: '\$2,847',
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
      amount: '\$685',
      subtitle: 'Due this week',
      color: const Color(0xFFFF3B30),
      icon: Icons.refresh,
      isPositive: false,
    ),
  ];

  final List<RecentTransaction> _recentTransactions = [
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, ${widget.userName ?? 'User'}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Text(
            'Track your expenses smartly',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
          ),
        ],
      ),
      leading: Builder(
        builder:
            (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black87),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
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
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
          onPressed: () {
            // Handle notifications
          },
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF007AFF).withValues(alpha: 0.1),
            child: const Text(
              'A',
              style: TextStyle(
                color: Color(0xFF007AFF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    'R',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF007AFF),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'RASEED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Smart Receipt Management',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('All Receipts'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Analytics'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () => Navigator.pop(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSmartWidgetsSection(),
          _buildActionHubSection(),
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

  Widget _buildSmartWidgetCard(SmartWidget widget) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () => _handleSmartWidgetTap(widget),
        child: Card(
          elevation: 4,
          shadowColor: widget.color.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  widget.color.withValues(alpha: 0.1),
                  widget.color.withValues(alpha: 0.05),
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

  void _handleSmartWidgetTap(SmartWidget widget) {
    if (widget.title == 'Upcoming Warranties') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WarrantiesScreen()),
      );
    }
    // Add other smart widget navigation handlers here
  }

  Widget _buildActionHubSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.4,
            children: [
              _buildActionCard(
                'AI Assistant',
                Icons.smart_toy,
                const Color(0xFF8E44AD),
                'Ask me anything',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatScreen()),
                  );
                },
              ),
              _buildActionCard(
                'Scan Receipt',
                Icons.camera_alt,
                const Color(0xFF007AFF),
                'Use OCR technology',
                () {
                  // Handle scan receipt
                },
              ),
              _buildActionCard(
                'Upload Image',
                Icons.photo_library,
                const Color(0xFF34C759),
                'From gallery',
                () {
                  // Handle upload image
                },
              ),
              _buildActionCard(
                'View Warranties',
                Icons.shield_outlined,
                const Color(0xFFFF9500),
                'Track expiry dates',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WarrantiesScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    String subtitle,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shadowColor: color.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
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
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _recentTransactions.length,
          itemBuilder: (context, index) {
            return _buildTransactionTile(_recentTransactions[index]);
          },
        ),
        const SizedBox(height: 100), // Space for FAB
      ],
    );
  }

  Widget _buildTransactionTile(RecentTransaction transaction) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: transaction.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(transaction.icon, color: transaction.color, size: 24),
          ),
          title: Text(
            transaction.merchant,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: Text(
            '${transaction.category} • ${transaction.time}',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          trailing: Text(
            transaction.amount,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem(Icons.home, 'Home', 0),
            _buildBottomNavItem(Icons.shield_outlined, 'Warranties', 1),
            const SizedBox(width: 40), // Space for FAB
            _buildBottomNavItem(Icons.refresh, 'Recurring', 2),
            _buildBottomNavItem(Icons.family_restroom, 'Family', 3),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF007AFF) : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF007AFF) : Colors.grey,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        // Handle AI Chatbot
        _showChatbotDialog();
      },
      backgroundColor: const Color(0xFF007AFF),
      child: const Icon(Icons.smart_toy, color: Colors.white, size: 28),
    );
  }

  void _showChatbotDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.smart_toy, color: Color(0xFF007AFF)),
              SizedBox(width: 8),
              Text('AI Assistant'),
            ],
          ),
          content: const Text(
            'Hello! I\'m your RASEED AI assistant. How can I help you manage your receipts and expenses today?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to full chatbot screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
              ),
              child: const Text(
                'Chat Now',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
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
