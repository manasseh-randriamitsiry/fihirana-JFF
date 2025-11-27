import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/hymn.dart';
import '../../services/hymn_service.dart';

import './user_management_screen_optimized.dart';
import './super_admin_dashboard.dart';
import '../../controller/color_controller.dart';
import '../../controller/shell_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../controller/auth_controller.dart';
import '../../widgets/skeleton_admin_list.dart';
import '../../widgets/admin/admin_stats_widgets.dart';
import '../../widgets/admin/admin_hymn_widgets.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  final HymnService _hymnService = HymnService();
  final ColorController _colorController = Get.find<ColorController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;
  List<String> selectedHymns = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkAdminAccess();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminAccess() async {
    // Wait a bit for auth controller to initialize if needed
    await Future.delayed(const Duration(milliseconds: 100));
    if (!Get.find<AuthController>().isAdmin) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noAdminPermission),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteSelectedHymns() async {
    if (selectedHymns.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() => isLoading = true);
    try {
      for (String hymnId in selectedHymns) {
        await _hymnService.deleteHymn(hymnId);
      }
      if (!mounted) return;

      selectedHymns.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectedHymnsDeleted),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.error}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Stream<Map<String, dynamic>> _getStats() {
    // Optimized stats using counters and aggregated queries
    return _firestore.collection('stats').doc('global').snapshots().asyncMap((statsDoc) async {
      // Get user counts efficiently
      final totalUsersQuery = await _firestore.collection('users').count().get();
      final totalUsers = totalUsersQuery.count ?? 0;
      
      // Active users count using query instead of loading all documents
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final activeUsersQuery = await _firestore
          .collection('users')
          .where('lastLogin', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
          .count()
          .get();
      final activeUsers = activeUsersQuery.count ?? 0;

      // Hymns count
      final hymnsSnapshot = await _firestore.collection('hymns').count().get();
      final totalHymns = hymnsSnapshot.count ?? 0;

      // Installations from stats doc or fallback
      final installations = statsDoc.data()?['installations'] as int? ?? 0;

      return {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'totalHymns': totalHymns,
        'installations': installations,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Obx(() {
      final backgroundColor = _colorController.backgroundColor.value;
      final textColor = _colorController.textColor.value;
      final iconColor = _colorController.iconColor.value;
      final primaryColor = _colorController.primaryColor.value;

      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.menu, color: iconColor),
            onPressed: () => Get.find<ShellController>().toggleDrawer(),
          ),
          title: Text(
            l10n.adminPanel,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
actions: [
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.red),
              onPressed: () => Get.to(() => const SuperAdminDashboard()),
              tooltip: 'Super Admin Dashboard',
            ),
            if (_tabController.index == 1 && selectedHymns.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: _deleteSelectedHymns,
              ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: primaryColor,
            unselectedLabelColor: textColor.withValues(alpha: 0.5),
            indicatorColor: primaryColor,
            onTap: (index) => setState(() {}), // Rebuild to show/hide actions
            tabs: [
              Tab(text: l10n.userManagement), // Reuse string or add "Users"
              Tab(text: l10n.hymns), // Reuse string or add "Hymns"
            ],
          ),
        ),
        body: Column(
          children: [
            // Stats Section
            StreamBuilder<Map<String, dynamic>>(
              stream: _getStats(),
              builder: (context, snapshot) {
                final stats = snapshot.data ??
                    {
                      'totalUsers': 0,
                      'activeUsers': 0,
                      'totalHymns': 0,
                      'installations': 0,
                    };

                return AdminStatsRowWidget(stats: stats);
              },
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Users Tab
                  const OptimizedUserManagementScreen(),

                  // Hymns Tab
                  _buildHymnsList(
                      l10n, textColor, primaryColor, backgroundColor),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }



  Widget _buildHymnsList(AppLocalizations l10n, Color textColor,
      Color primaryColor, Color backgroundColor) {
    return StreamBuilder<List<Hymn>>(
      stream: _hymnService.getFirebaseHymnsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text('${l10n.error}: ${snapshot.error}',
                  style: TextStyle(color: textColor)));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SkeletonAdminList();
        }

        final hymns = snapshot.data ?? [];
        hymns.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (hymns.isEmpty) {
          return const AdminEmptyHymnsWidget();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: hymns.length,
          itemBuilder: (context, index) {
            final hymn = hymns[index];
            final isSelected = selectedHymns.contains(hymn.id);

            return AdminHymnListItemWidget(
              hymn: hymn,
              isSelected: isSelected,
              primaryColor: primaryColor,
              onSelectionChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    selectedHymns.add(hymn.id);
                  } else {
                    selectedHymns.remove(hymn.id);
                  }
                });
              },
            );
          },
        );
      },
    );
  }
}
