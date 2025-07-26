import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class SpendingInsightsScreen extends StatefulWidget {
  const SpendingInsightsScreen({Key? key}) : super(key: key);

  @override
  State<SpendingInsightsScreen> createState() => _SpendingInsightsScreenState();
}

class _SpendingInsightsScreenState extends State<SpendingInsightsScreen>
    with SingleTickerProviderStateMixin {
  Widget _buildDebugInfoCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.yellow[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.yellow[700] ?? Colors.amber, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Debug Info:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.yellow[900] ?? Colors.amber[900],
            ),
          ),
          const SizedBox(height: 4),
          Text('Fetched items: $_fetchedItemCount'),
          Text('User ID: $_debugUserId'),
          Text(
            'Date Range: ${DateFormat('yyyy-MM-dd').format(_startDate)} to ${DateFormat('yyyy-MM-dd').format(_endDate)}',
          ),
        ],
      ),
    );
  }

  int _fetchedItemCount = 0;
  String _debugUserId = '';
  final user = FirebaseAuth.instance.currentUser;
  late TabController _tabController;

  // Selected date range
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // Budget configurations
  Map<String, double> _budgets = {};
  bool _isLoading = true;

  // Spending data
  Map<String, double> _categorySpending = {};
  double _totalSpending = 0;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBudgets();
    _fetchSpendingData();
  }

  Future<void> _loadBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = user?.uid;
    if (userId == null) return;

    final budgetKeys =
        prefs
            .getKeys()
            .where((key) => key.startsWith('budget_${userId}_'))
            .toList();

    setState(() {
      for (final key in budgetKeys) {
        final category = key.replaceFirst('budget_${userId}_', '');
        _budgets[category] = prefs.getDouble(key) ?? 0.0;
      }
    });
  }

  Future<void> _saveBudget(String category, double amount) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = user?.uid;
    if (userId == null) return;

    await prefs.setDouble('budget_${userId}_$category', amount);
    setState(() {
      _budgets[category] = amount;
    });
  }

  StreamSubscription<QuerySnapshot>? _lineItemsSubscription;

  Future<void> _fetchSpendingData() async {
    setState(() {
      _isLoading = true;
    });

    final userId = user?.uid;
    if (userId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // For debug info
    _debugUserId = userId;

    // Cancel previous subscription if any
    await _lineItemsSubscription?.cancel();

    final query = FirebaseFirestore.instance
        .collection('line_items')
        .where('user_id', isEqualTo: userId)
        .where(
          'purchase_date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate),
        )
        .where(
          'purchase_date',
          isLessThanOrEqualTo: Timestamp.fromDate(_endDate),
        );

    _lineItemsSubscription = query.snapshots().listen(
      (snapshot) {
        final Map<String, double> categorySpending = {};
        double totalSpending = 0;

        _fetchedItemCount = snapshot.docs.length;
        for (int i = 0; i < snapshot.docs.length && i < 3; i++) {
          debugPrint('Fetched doc #$i: ' + snapshot.docs[i].data().toString());
        }
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final category = data['category'] ?? 'Uncategorized';
          final priceRaw = data['price'];
          double price = 0.0;
          if (priceRaw is int) {
            price = priceRaw.toDouble();
          } else if (priceRaw is double) {
            price = priceRaw;
          } else if (priceRaw is String) {
            price = double.tryParse(priceRaw) ?? 0.0;
          }
          debugPrint(
            'Doc category: $category, price: $priceRaw (parsed: $price)',
          );
          categorySpending[category] =
              (categorySpending[category] ?? 0) + price;
          totalSpending += price;
        }

        setState(() {
          _categorySpending = categorySpending;
          _totalSpending = totalSpending;
          _categories = categorySpending.keys.toList()..sort();
          _isLoading = false;
        });
      },
      onError: (e) {
        debugPrint('Error fetching spending data: $e');
        setState(() {
          _isLoading = false;
        });
      },
    );
  }

  @override
  void dispose() {
    _lineItemsSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
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
      _fetchSpendingData();
    }
  }

  void _showBudgetSettingDialog(String category) {
    final TextEditingController controller = TextEditingController(
      text: (_budgets[category] ?? 0.0).toString(),
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Set Budget for $category'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monthly Budget',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(controller.text) ?? 0.0;
                  _saveBudget(category, amount);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF42A5F5),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Insights'),
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
            Tab(text: 'Categories'),
            Tab(text: 'Budgets'),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calendar_today,
                color: Color(0xFF5F6368),
                size: 20,
              ),
            ),
            onPressed: _showDateRangePicker,
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildCategoriesTab(),
                  _buildBudgetsTab(),
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
          _buildDebugInfoCard(),
          _buildDateRangeCard(),
          const SizedBox(height: 16),
          _buildTotalSpendingCard(),
          const SizedBox(height: 24),
          _buildSpendingPieChart(),
          const SizedBox(height: 24),
          _buildInsightsCard(),
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
            'Total Spending',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_totalSpending.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Across ${_categories.length} categories',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingPieChart() {
    if (_categorySpending.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No spending data available for the selected period.'),
        ),
      );
    }

    // Generate colors for the pie chart
    final List<Color> colors = [
      const Color(0xFF64B5F6),
      const Color(0xFF42A5F5),
      const Color(0xFF1E88E5),
      const Color(0xFF1976D2),
      const Color(0xFF1565C0),
      const Color(0xFF0D47A1),
    ];

    final sections = <PieChartSectionData>[];
    int colorIndex = 0;

    _categorySpending.forEach((category, amount) {
      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: amount,
          title: '', // Remove percentage text from pie slices
          radius: 80, // Reduced radius for better layout
          titleStyle: const TextStyle(
            fontSize: 0, // Hide any text on slices
            fontWeight: FontWeight.bold,
            color: Colors.transparent,
          ),
        ),
      );
      colorIndex++;
    });

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
            'Spending by Category',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250, // Increased height for better proportion
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 60, // Increased center space
                sectionsSpace: 3, // Slightly more space between sections
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Column(
            children: List.generate(_categorySpending.length, (index) {
              final category = _categorySpending.keys.elementAt(index);
              final amount = _categorySpending[category]!;
              final percentage = (amount / _totalSpending * 100);
              final color = colors[index % colors.length];
              return _buildLegendItem(category, color, amount, percentage);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    String category,
    Color color,
    double amount,
    double percentage,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF202124),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF202124),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsCard() {
    // Find the highest spending category
    String topCategory = 'None';
    double topAmount = 0;

    _categorySpending.forEach((category, amount) {
      if (amount > topAmount) {
        topAmount = amount;
        topCategory = category;
      }
    });

    // Calculate budget status
    int overBudgetCount = 0;
    for (final category in _categories) {
      final budget = _budgets[category] ?? 0;
      if (budget > 0 && (_categorySpending[category] ?? 0) > budget) {
        overBudgetCount++;
      }
    }

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
            'Spending Insights',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildInsightItem(
            icon: Icons.trending_up,
            title: 'Top Category',
            subtitle:
                '$topCategory (${(_categorySpending[topCategory] ?? 0).toStringAsFixed(2)})',
          ),
          const Divider(),
          _buildInsightItem(
            icon: Icons.warning_amber,
            title: 'Budget Status',
            subtitle:
                overBudgetCount > 0
                    ? '$overBudgetCount ${overBudgetCount == 1 ? 'category is' : 'categories are'} over budget'
                    : 'All categories are within budget',
            color: overBudgetCount > 0 ? Colors.orange : Colors.green,
          ),
          const Divider(),
          _buildInsightItem(
            icon: Icons.calendar_today,
            title: 'Daily Average',
            subtitle:
                '${(_totalSpending / _getDaysInRange()).toStringAsFixed(2)} per day',
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (color ?? const Color(0xFF64B5F6)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color ?? const Color(0xFF64B5F6),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab() {
    if (_categories.isEmpty) {
      return const Center(
        child: Text('No spending data available for the selected period.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final amount = _categorySpending[category] ?? 0;
        final budget = _budgets[category] ?? 0;
        final percentage = budget > 0 ? (amount / budget * 100) : 0;

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
                      category,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings, size: 20),
                      onPressed: () => _showBudgetSettingDialog(category),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF42A5F5),
                      ),
                    ),
                    if (budget > 0)
                      Text(
                        'of ${budget.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (budget > 0) ...[
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percentage > 100 ? Colors.red : const Color(0xFF42A5F5),
                    ),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color:
                              percentage > 100 ? Colors.red : Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (percentage > 100)
                        const Text(
                          'Over Budget',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ] else ...[
                  OutlinedButton(
                    onPressed: () => _showBudgetSettingDialog(category),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF42A5F5),
                      side: const BorderSide(color: Color(0xFF42A5F5)),
                    ),
                    child: const Text('Set Budget'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBudgetsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Budget Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildBudgetSummaryRow(
                    label: 'Total Budgeted',
                    value: _budgets.values.fold(
                      0.0,
                      (sum, value) => sum + value,
                    ),
                    color: const Color(0xFF42A5F5),
                  ),
                  const SizedBox(height: 8),
                  _buildBudgetSummaryRow(
                    label: 'Total Spent',
                    value: _totalSpending,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 8),
                  _buildBudgetSummaryRow(
                    label: 'Remaining',
                    value:
                        _budgets.values.fold(0.0, (sum, value) => sum + value) -
                        _totalSpending,
                    color: Colors.green,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Category Budgets',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final budget = _budgets[category] ?? 0;
                final spent = _categorySpending[category] ?? 0;
                final remaining = budget - spent;
                final percentage = budget > 0 ? (spent / budget * 100) : 0;

                return ListTile(
                  title: Text(
                    category,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle:
                      budget > 0
                          ? LinearProgressIndicator(
                            value: percentage > 100 ? 1 : percentage / 100,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              percentage > 100
                                  ? Colors.red
                                  : const Color(0xFF42A5F5),
                            ),
                            minHeight: 4,
                          )
                          : const Text('No budget set'),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${budget.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        remaining >= 0
                            ? '${remaining.toStringAsFixed(0)} left'
                            : '${(-remaining).toStringAsFixed(0)} over',
                        style: TextStyle(
                          color: remaining >= 0 ? Colors.green : Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _showBudgetSettingDialog(category),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSummaryRow({
    required String label,
    required double value,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 16)),
          ],
        ),
        Text(
          '${value.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  int _getDaysInRange() {
    return _endDate.difference(_startDate).inDays + 1;
  }
}
