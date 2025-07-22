import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'chat_screen.dart';
import 'warranties_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  final String? userName;
  const HomeScreen({super.key, this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Controllers for receipt entry form
  final _merchantController = TextEditingController();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  DateTime? _selectedDate;
  String? _receiptImagePath;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImageFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _receiptImagePath = pickedFile.path;
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _receiptImagePath = pickedFile.path;
      });
    }
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    super.dispose();
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
                      widget.isPositive ? Icons.trending_up : Icons.trending_down,
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
      leading: Builder(
        builder: (context) => IconButton(
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
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WarrantiesScreen()),
      );
    }
    // Add other smart widget navigation handlers here
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
        _showReceiptEntryForm();
      },
      backgroundColor: const Color(0xFF007AFF),
      child: const Icon(Icons.add, color: Colors.white, size: 28),
    );
  }

  void _showReceiptEntryForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add Receipt',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _merchantController,
                      decoration: const InputDecoration(
                        labelText: 'Merchant',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedDate == null
                                ? 'Date: Not selected'
                                : 'Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                _selectedDate = picked;
                              });
                              setModalState(() {});
                            }
                          },
                          child: const Text('Pick Date'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (_receiptImagePath != null && File(_receiptImagePath!).existsSync())
                          Container(
                            width: 60,
                            height: 60,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: FileImage(File(_receiptImagePath!)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 60,
                            height: 60,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[200],
                            ),
                            child: const Icon(Icons.receipt_long, color: Colors.grey),
                          ),
                        Expanded(
                          child: Column(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                                  if (pickedFile != null) {
                                    setState(() {
                                      _receiptImagePath = pickedFile.path;
                                    });
                                    setModalState(() {});
                                  }
                                },
                                icon: const Icon(Icons.photo_library),
                                label: const Text('Gallery'),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
                                  if (pickedFile != null) {
                                    setState(() {
                                      _receiptImagePath = pickedFile.path;
                                    });
                                    setModalState(() {});
                                  }
                                },
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Camera'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_receiptImagePath != null)
                      Center(
                        child: TextButton.icon(
                          onPressed: () async {
                            if (_receiptImagePath != null) {
                              final File file = File(_receiptImagePath!);
                              final bytes = await file.readAsBytes();
                              final base64Image = base64Encode(bytes);

                              try {
                                final response = await http.post(
                                  Uri.parse('https://parse-receipt-python-979444618103.asia-south1.run.app'),
                                  headers: {'Content-Type': 'application/json'},
                                  body: jsonEncode({'image': base64Image}),
                                );

                                if (response.statusCode == 200) {
                                  final data = jsonDecode(response.body);
                                  setState(() {
                                    _merchantController.text = data['merchant'] ?? '';
                                    _amountController.text = data['amount'] ?? '';
                                    _categoryController.text = data['category'] ?? '';
                                    _selectedDate = data['date'] != null ? DateTime.parse(data['date']) : null;
                                  });
                                  setModalState(() {});
                                } else {
                                  print('Failed to parse receipt: ${response.body}');
                                }
                              } catch (e) {
                                print('Error occurred while parsing receipt: ${e}');
                              }
                            }
                          },
                          icon: const Icon(Icons.camera_alt, color: Color(0xFF007AFF)),
                          label: const Text(
                            'Scan Receipt',
                            style: TextStyle(
                              color: Color(0xFF007AFF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Save receipt (add to _recentTransactions)
                          if (_merchantController.text.isNotEmpty && _amountController.text.isNotEmpty) {
                            setState(() {
                              _recentTransactions.insert(0, RecentTransaction(
                                merchant: _merchantController.text,
                                amount: _amountController.text,
                                category: _categoryController.text.isNotEmpty ? _categoryController.text : 'Other',
                                icon: Icons.receipt_long,
                                time: _selectedDate != null ? _selectedDate!.toLocal().toString().split(' ')[0] : 'Now',
                                color: const Color(0xFF007AFF),
                              ));
                              _merchantController.clear();
                              _amountController.clear();
                              _categoryController.clear();
                              _selectedDate = null;
                              _receiptImagePath = null;
                            });
                            Navigator.of(context).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007AFF),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Add Receipt', 
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
