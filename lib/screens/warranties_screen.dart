import 'package:flutter/material.dart';
import 'warranty_detail_screen.dart';
import '../widgets/shared_bottom_nav.dart';
import '../widgets/shared_floating_action_button.dart';

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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Product Warranties',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        shadowColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[200]!, Colors.grey[100]!],
              ),
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.search, size: 20),
              ),
              onPressed: () {
                // TODO: Implement search functionality
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.filter_list, size: 20),
              ),
              onPressed: _showFilterBottomSheet,
            ),
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
      bottomNavigationBar: const SharedBottomNav(currentIndex: 1),
      floatingActionButton: const SharedFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildStatsOverview() {
    final expiringSoon = _warranties.where((w) => w.isExpiringSoon).length;
    final expiringThisMonth =
        _warranties.where((w) => w.isExpiringThisMonth).length;
    final expired = _warranties.where((w) => w.isExpired).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Card(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFFAFBFC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Warranty Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildStatItem(
                    'Total',
                    _warranties.length.toString(),
                    const Color(0xFF007AFF),
                    Icons.shield_outlined,
                  ),
                  _buildStatItem(
                    'Expiring Soon',
                    expiringSoon.toString(),
                    const Color(0xFFFF9500),
                    Icons.warning_amber_outlined,
                  ),
                  _buildStatItem(
                    'This Month',
                    expiringThisMonth.toString(),
                    const Color(0xFFFFCC02),
                    Icons.schedule_outlined,
                  ),
                  _buildStatItem(
                    'Expired',
                    expired.toString(),
                    const Color(0xFFFF3B30),
                    Icons.error_outline,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.2), width: 1),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final option = _filterOptions[index];
          final isSelected = _selectedFilter == option;

          return Container(
            margin: EdgeInsets.only(right: 12, left: index == 0 ? 4 : 0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedFilter = option;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient:
                        isSelected
                            ? const LinearGradient(
                              colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                            : null,
                    color: isSelected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isSelected ? Colors.transparent : Colors.grey[300]!,
                      width: 1,
                    ),
                    boxShadow:
                        isSelected
                            ? [
                              BoxShadow(
                                color: const Color(0xFF007AFF).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                            : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                  ),
                  child: Text(
                    option,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
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
    if (isExpired) return 'Expired  A0${daysRemaining.abs()} days ago';
    if (daysRemaining == 0) return 'Expires today';
    if (daysRemaining == 1) return 'Expires tomorrow';
    return 'Expires in $daysRemaining days';
  }
}

class WarrantyCard extends StatelessWidget {
  final WarrantyItem warranty;
  final VoidCallback onTap;

  const WarrantyCard({super.key, required this.warranty, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [Colors.white, Colors.grey[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                // Enhanced Category Icon with better visual hierarchy
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        warranty.urgencyColor.withOpacity(0.15),
                        warranty.urgencyColor.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: warranty.urgencyColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    warranty.categoryIcon,
                    color: warranty.urgencyColor,
                    size: 28,
                  ),
                ),

                const SizedBox(width: 16),

                // Enhanced Product Info with better typography
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        warranty.productName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.store_outlined,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${warranty.storeName} • ${_formatDate(warranty.purchaseDate)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Enhanced status badge with better design
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              warranty.urgencyColor.withOpacity(0.15),
                              warranty.urgencyColor.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: warranty.urgencyColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: warranty.urgencyColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              warranty.urgencyText,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: warranty.urgencyColor,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Enhanced trailing section with urgency indicator
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_right,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Urgency indicator dot
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: warranty.urgencyColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: warranty.urgencyColor.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
