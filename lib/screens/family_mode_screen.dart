import 'package:flutter/material.dart';
import 'family_analysis.dart';
import 'family_management_screen.dart';
import '../widgets/shared_drawer.dart';

class FamilyModeScreen extends StatefulWidget {
  const FamilyModeScreen({Key? key}) : super(key: key);

  @override
  State<FamilyModeScreen> createState() => _FamilyModeScreenState();
}

class _FamilyModeScreenState extends State<FamilyModeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const SharedDrawer(),
      appBar: AppBar(
        title: const Text('Family Mode'),
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
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            Tab(icon: Icon(Icons.group_add), text: 'Management'),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: TabBarView(
        controller: _tabController,
        children: const [FamilyAnalysisScreen(), FamilyManagementScreen()],
      ),
    );
  }
}
