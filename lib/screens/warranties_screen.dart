import 'package:flutter/material.dart';
import 'warranty_detail_screen.dart';

class WarrantyItem {
  final String id;
  final String productName;
  final String category;
  final String storeName;
  final DateTime purchaseDate;
  final DateTime warrantyExpiry;
  final String receiptImageUrl;
  final String storeLocation;
  final String supportUrl;
  final String websiteUrl;
  final IconData categoryIcon;

  WarrantyItem({
    required this.id,
    required this.productName,
    required this.category,
    required this.storeName,
    required this.purchaseDate,
    required this.warrantyExpiry,
    required this.receiptImageUrl,
    required this.storeLocation,
    required this.supportUrl,
    required this.websiteUrl,
    required this.categoryIcon,
  });

  int get daysRemaining {
    final now = DateTime.now();
    return warrantyExpiry.difference(now).inDays;
  }

  bool get isExpired => daysRemaining < 0;

  bool get isExpiringSoon => daysRemaining <= 7 && daysRemaining >= 0;

  bool get isExpiringThisMonth => daysRemaining <= 30 && daysRemaining > 7;

  Color get urgencyColor {
    if (isExpired) return const Color(0xFFFF3B30); // Red
    if (isExpiringSoon) return const Color(0xFFFF9500); // Orange
    if (isExpiringThisMonth) return const Color(0xFFFFCC02); // Yellow
    return const Color(0xFF34C759); // Green
  }

  String get urgencyText {
    if (isExpired) return 'Expired ${daysRemaining.abs()} days ago';
    if (daysRemaining == 0) return 'Expires today';
    if (daysRemaining == 1) return 'Expires tomorrow';
    return 'Expires in $daysRemaining days';
  }
}

class WarrantiesScreen extends StatefulWidget {
  const WarrantiesScreen({super.key});

  @override
  State<WarrantiesScreen> createState() => _WarrantiesScreenState();
}

class _WarrantiesScreenState extends State<WarrantiesScreen> {
  final List<WarrantyItem> _warranties = [
    WarrantyItem(
      id: '1',
      productName: 'MacBook Pro 16-inch',
      category: 'Electronics',
      storeName: 'Apple Store',
      purchaseDate: DateTime(2024, 1, 15),
      warrantyExpiry: DateTime(2025, 1, 15),
      receiptImageUrl:
          'https://via.placeholder.com/400x600/f0f0f0/333?text=Apple+Receipt',
      storeLocation: 'Apple Fifth Avenue, New York, NY',
      supportUrl: 'https://support.apple.com',
      websiteUrl: 'https://apple.com',
      categoryIcon: Icons.laptop_mac,
    ),
    WarrantyItem(
      id: '2',
      productName: 'Sony WH-1000XM5 Headphones',
      category: 'Audio',
      storeName: 'Best Buy',
      purchaseDate: DateTime(2024, 6, 10),
      warrantyExpiry: DateTime(2025, 8, 2),
      receiptImageUrl:
          'https://via.placeholder.com/400x600/0066cc/white?text=Best+Buy+Receipt',
      storeLocation: 'Best Buy Union Square, New York, NY',
      supportUrl: 'https://sony.com/support',
      websiteUrl: 'https://sony.com',
      categoryIcon: Icons.headphones,
    ),
    WarrantyItem(
      id: '3',
      productName: 'Samsung 65" QLED TV',
      category: 'Home Entertainment',
      storeName: 'Samsung Store',
      purchaseDate: DateTime(2023, 12, 20),
      warrantyExpiry: DateTime(2025, 7, 30),
      receiptImageUrl:
          'https://via.placeholder.com/400x600/1f1f1f/white?text=Samsung+Receipt',
      storeLocation: 'Samsung Experience Store, Manhattan',
      supportUrl: 'https://samsung.com/support',
      websiteUrl: 'https://samsung.com',
      categoryIcon: Icons.tv,
    ),
    WarrantyItem(
      id: '4',
      productName: 'Dyson V15 Detect Vacuum',
      category: 'Home Appliances',
      storeName: 'Dyson Demo Store',
      purchaseDate: DateTime(2024, 3, 8),
      warrantyExpiry: DateTime(2026, 3, 8),
      receiptImageUrl:
          'https://via.placeholder.com/400x600/663399/white?text=Dyson+Receipt',
      storeLocation: 'Dyson Demo Store, SoHo, NYC',
      supportUrl: 'https://dyson.com/support',
      websiteUrl: 'https://dyson.com',
      categoryIcon: Icons.cleaning_services,
    ),
    WarrantyItem(
      id: '5',
      productName: 'iPhone 15 Pro',
      category: 'Electronics',
      storeName: 'Apple Store',
      purchaseDate: DateTime(2024, 9, 22),
      warrantyExpiry: DateTime(2025, 9, 22),
      receiptImageUrl:
          'https://via.placeholder.com/400x600/f0f0f0/333?text=Apple+iPhone+Receipt',
      storeLocation: 'Apple Store SoHo, New York, NY',
      supportUrl: 'https://support.apple.com',
      websiteUrl: 'https://apple.com',
      categoryIcon: Icons.smartphone,
    ),
    WarrantyItem(
      id: '6',
      productName: 'Instant Pot Duo 7-in-1',
      category: 'Kitchen Appliances',
      storeName: 'Williams Sonoma',
      purchaseDate: DateTime(2024, 11, 15),
      warrantyExpiry: DateTime(2025, 8, 10),
      receiptImageUrl:
          'https://via.placeholder.com/400x600/8B4513/white?text=Williams+Sonoma',
      storeLocation: 'Williams Sonoma, Columbus Circle',
      supportUrl: 'https://instantpot.com/support',
      websiteUrl: 'https://instantpot.com',
      categoryIcon: Icons.kitchen,
    ),
  ];

  String _selectedFilter = 'All';
  final List<String> _filterOptions = [
    'All',
    'Expiring Soon',
    'This Month',
    'Active',
    'Expired',
  ];

  @override
  Widget build(BuildContext context) {
    final filteredWarranties = _getFilteredWarranties();
    final sortedWarranties = _sortWarrantiesByUrgency(filteredWarranties);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Product Warranties',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        shadowColor: Colors.black12,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Overview
          _buildStatsOverview(),

          // Filter Chips
          _buildFilterChips(),

          // Warranties List
          Expanded(
            child:
                sortedWarranties.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                      onRefresh: _refreshWarranties,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: sortedWarranties.length,
                        itemBuilder: (context, index) {
                          return WarrantyCard(
                            warranty: sortedWarranties[index],
                            onTap:
                                () => _navigateToWarrantyDetail(
                                  sortedWarranties[index],
                                ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview() {
    final expiringSoon = _warranties.where((w) => w.isExpiringSoon).length;
    final expiringThisMonth =
        _warranties.where((w) => w.isExpiringThisMonth).length;
    final expired = _warranties.where((w) => w.isExpired).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem(
            'Total',
            _warranties.length.toString(),
            const Color(0xFF007AFF),
          ),
          _buildStatItem(
            'Expiring Soon',
            expiringSoon.toString(),
            const Color(0xFFFF9500),
          ),
          _buildStatItem(
            'This Month',
            expiringThisMonth.toString(),
            const Color(0xFFFFCC02),
          ),
          _buildStatItem(
            'Expired',
            expired.toString(),
            const Color(0xFFFF3B30),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final option = _filterOptions[index];
          final isSelected = _selectedFilter == option;

          return Container(
            margin: EdgeInsets.only(right: 8, left: index == 0 ? 0 : 0),
            child: FilterChip(
              label: Text(
                option,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = option;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF007AFF),
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: isSelected ? const Color(0xFF007AFF) : Colors.grey[300]!,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No warranties found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start scanning receipts to track your warranties',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<WarrantyItem> _getFilteredWarranties() {
    switch (_selectedFilter) {
      case 'Expiring Soon':
        return _warranties.where((w) => w.isExpiringSoon).toList();
      case 'This Month':
        return _warranties.where((w) => w.isExpiringThisMonth).toList();
      case 'Active':
        return _warranties.where((w) => !w.isExpired).toList();
      case 'Expired':
        return _warranties.where((w) => w.isExpired).toList();
      default:
        return _warranties;
    }
  }

  List<WarrantyItem> _sortWarrantiesByUrgency(List<WarrantyItem> warranties) {
    warranties.sort((a, b) {
      // Expired items first (most overdue first)
      if (a.isExpired && b.isExpired) {
        return a.daysRemaining.compareTo(b.daysRemaining);
      }
      if (a.isExpired) return -1;
      if (b.isExpired) return 1;

      // Then expiring soon (least days remaining first)
      if (a.isExpiringSoon && b.isExpiringSoon) {
        return a.daysRemaining.compareTo(b.daysRemaining);
      }
      if (a.isExpiringSoon) return -1;
      if (b.isExpiringSoon) return 1;

      // Then expiring this month
      if (a.isExpiringThisMonth && b.isExpiringThisMonth) {
        return a.daysRemaining.compareTo(b.daysRemaining);
      }
      if (a.isExpiringThisMonth) return -1;
      if (b.isExpiringThisMonth) return 1;

      // Finally, sort by days remaining (ascending)
      return a.daysRemaining.compareTo(b.daysRemaining);
    });

    return warranties;
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Warranties',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              ..._filterOptions.map(
                (option) => ListTile(
                  title: Text(option),
                  leading: Radio<String>(
                    value: option,
                    groupValue: _selectedFilter,
                    onChanged: (value) {
                      setState(() {
                        _selectedFilter = value!;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _refreshWarranties() async {
    // Simulate refresh delay
    await Future.delayed(const Duration(seconds: 1));
    // In a real app, this would fetch updated warranty data
  }

  void _navigateToWarrantyDetail(WarrantyItem warranty) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WarrantyDetailScreen(warranty: warranty),
      ),
    );
  }
}

class WarrantyCard extends StatelessWidget {
  final WarrantyItem warranty;
  final VoidCallback onTap;

  const WarrantyCard({super.key, required this.warranty, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Category Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: warranty.urgencyColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    warranty.categoryIcon,
                    color: warranty.urgencyColor,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),

                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        warranty.productName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${warranty.storeName} • ${_formatDate(warranty.purchaseDate)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: warranty.urgencyColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          warranty.urgencyText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: warranty.urgencyColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow Icon
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
