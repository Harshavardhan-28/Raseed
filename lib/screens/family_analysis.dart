import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/family_models.dart';
import '../services/family_service.dart';

class FamilyAnalysisScreen extends StatefulWidget {
  const FamilyAnalysisScreen({Key? key}) : super(key: key);

  @override
  State<FamilyAnalysisScreen> createState() => _FamilyAnalysisScreenState();
}

class _FamilyAnalysisScreenState extends State<FamilyAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Family? _family;
  List<Map<String, dynamic>> _familyMembers = [];
  bool _isLoading = true;

  // Analytics data
  Map<String, double> _memberSpending = {};
  Map<String, double> _categorySpending = {};
  double _totalFamilySpending = 0;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFamilyData();
  }

  Future<void> _loadFamilyData() async {
    setState(() => _isLoading = true);

    try {
      final family = await FamilyService.getUserFamily();
      if (family == null) {
        setState(() => _isLoading = false);
        return;
      }

      final members = await FamilyService.getFamilyMembers(family.id);

      setState(() {
        _family = family;
        _familyMembers = members;
      });

      await _fetchFamilySpendingData();
    } catch (e) {
      debugPrint('Error loading family data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchFamilySpendingData() async {
    if (_family == null) return;

    final memberSpending = <String, double>{};
    final categorySpending = <String, double>{};
    double totalSpending = 0;

    // Query all line items for family members
    final query =
        await FirebaseFirestore.instance
            .collection('line_items')
            .where('user_id', whereIn: _family!.memberIds)
            .where(
              'purchase_date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate),
            )
            .where(
              'purchase_date',
              isLessThanOrEqualTo: Timestamp.fromDate(_endDate),
            )
            .get();

    for (final doc in query.docs) {
      final data = doc.data();
      final userId = data['user_id'] ?? '';
      final category = data['category'] ?? 'Uncategorized';

      double price = 0.0;
      final priceRaw = data['price'];
      if (priceRaw is int) {
        price = priceRaw.toDouble();
      } else if (priceRaw is double) {
        price = priceRaw;
      } else if (priceRaw is String) {
        price = double.tryParse(priceRaw) ?? 0.0;
      }

      // Find member name
      final member = _familyMembers.firstWhere(
        (m) => m['id'] == userId,
        orElse: () => {'name': 'Unknown', 'email': 'unknown@example.com'},
      );
      final memberName = member['name'] ?? member['email'] ?? 'Unknown';

      memberSpending[memberName] = (memberSpending[memberName] ?? 0) + price;
      categorySpending[category] = (categorySpending[category] ?? 0) + price;
      totalSpending += price;
    }

    setState(() {
      _memberSpending = memberSpending;
      _categorySpending = categorySpending;
      _totalFamilySpending = totalSpending;
    });
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF42A5F5),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF202124),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchFamilySpendingData();
    }
  }

  void _showInviteMemberDialog() {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Invite Family Member'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter the email address of the person you want to invite:',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final email = emailController.text.trim();
                  if (email.isEmpty) return;

                  try {
                    await FamilyService.sendInvitation(_family!.id, email);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invitation sent successfully!'),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF42A5F5),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Send Invite'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Family Analytics'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: const Color(0xFF202124),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_family == null) {
      return _buildNoFamilyScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_family!.name),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF202124),
        titleTextStyle: const TextStyle(
          color: Color(0xFF202124),
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF42A5F5),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF42A5F5),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Members'),
            Tab(text: 'Categories'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _showDateRangePicker,
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showInviteMemberDialog,
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildMembersTab(),
          _buildCategoriesTab(),
        ],
      ),
    );
  }

  Widget _buildNoFamilyScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Analytics'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF202124),
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF42A5F5).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.family_restroom,
                  size: 64,
                  color: Color(0xFF42A5F5),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No Family Found',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Create a family or accept an invitation to view combined spending analytics.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _showCreateFamilyDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF42A5F5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('Create Family'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateFamilyDialog() {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Create Family'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Family Name',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;

                  try {
                    await FamilyService.createFamily(name);
                    Navigator.pop(context);
                    _loadFamilyData();
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF42A5F5),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Create'),
              ),
            ],
          ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateRangeCard(),
          const SizedBox(height: 16),
          _buildTotalSpendingCard(),
          const SizedBox(height: 24),
          _buildMemberSpendingChart(),
          const SizedBox(height: 24),
          _buildCategoryChart(),
        ],
      ),
    );
  }

  Widget _buildDateRangeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64B5F6).withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.date_range, color: Color(0xFF42A5F5)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Date Range',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('MMM d, yyyy').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _showDateRangePicker,
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSpendingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF64B5F6), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64B5F6).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Family Spending',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_totalFamilySpending.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Across ${_familyMembers.length} family members',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberSpendingChart() {
    if (_memberSpending.isEmpty) {
      return const Center(child: Text('No spending data available'));
    }

    final colors = [
      const Color(0xFF64B5F6),
      const Color(0xFF42A5F5),
      const Color(0xFF1E88E5),
      const Color(0xFF1976D2),
      const Color(0xFF1565C0),
      const Color(0xFF0D47A1),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64B5F6).withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending by Member',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                barGroups:
                    _memberSpending.entries.map((entry) {
                      final index = _memberSpending.keys.toList().indexOf(
                        entry.key,
                      );
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value,
                            color: colors[index % colors.length],
                            width: 20,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }).toList(),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _memberSpending.length) {
                          final name = _memberSpending.keys.elementAt(index);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              name.split(' ').first,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChart() {
    if (_categorySpending.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = [
      const Color(0xFF64B5F6),
      const Color(0xFF42A5F5),
      const Color(0xFF1E88E5),
      const Color(0xFF1976D2),
      const Color(0xFF1565C0),
      const Color(0xFF0D47A1),
    ];

    final sections =
        _categorySpending.entries.map((entry) {
          final index = _categorySpending.keys.toList().indexOf(entry.key);
          return PieChartSectionData(
            color: colors[index % colors.length],
            value: entry.value,
            title: '',
            radius: 80,
          );
        }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64B5F6).withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Breakdown',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 60,
                sectionsSpace: 3,
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children:
                _categorySpending.entries.map((entry) {
                  final index = _categorySpending.keys.toList().indexOf(
                    entry.key,
                  );
                  final color = colors[index % colors.length];
                  final percentage = (entry.value / _totalFamilySpending * 100);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(entry.key)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${entry.value.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _familyMembers.length,
      itemBuilder: (context, index) {
        final member = _familyMembers[index];
        final memberName = member['name'] ?? member['email'] ?? 'Unknown';
        final memberSpending = _memberSpending[memberName] ?? 0.0;
        final isCurrentUser =
            member['id'] == FirebaseAuth.instance.currentUser?.uid;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF64B5F6).withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF42A5F5),
              child: Text(
                memberName.isNotEmpty ? memberName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Row(
              children: [
                Text(
                  memberName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (isCurrentUser) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF42A5F5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'You',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF42A5F5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Text(member['email'] ?? ''),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${memberSpending.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF42A5F5),
                  ),
                ),
                Text(
                  '${_totalFamilySpending > 0 ? (memberSpending / _totalFamilySpending * 100).toStringAsFixed(1) : 0}%',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoriesTab() {
    if (_categorySpending.isEmpty) {
      return const Center(child: Text('No category data available'));
    }

    final sortedCategories =
        _categorySpending.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final entry = sortedCategories[index];
        final percentage = (entry.value / _totalFamilySpending * 100);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF64B5F6).withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${entry.value.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF42A5F5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF42A5F5),
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Text(
                  '${percentage.toStringAsFixed(1)}% of total family spending',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
