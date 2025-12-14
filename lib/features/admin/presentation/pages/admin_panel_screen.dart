import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/hymn/data/services/hymn_service.dart';
import './user_management_screen.dart';
import './super_admin_dashboard.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/core/navigation/shell_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/features/auth/presentation/controllers/auth_controller.dart';
import 'package:fihirana/shared/widgets/common/skeleton_admin_list.dart';
import 'package:fihirana/features/admin/presentation/widgets/admin_stats_widgets.dart';
import 'package:fihirana/features/admin/presentation/widgets/admin_hymn_widgets.dart';
import 'package:fihirana/features/admin/presentation/widgets/deleted_recordings_widget.dart';
import 'package:fihirana/features/admin/presentation/controllers/admin_controller.dart';
import 'package:fihirana/features/admin/di/admin_di.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  final HymnService _hymnService = HymnService();
  final ColorController _colorController = Get.find<ColorController>();
  late TabController _tabController;
  List<String> selectedHymns = [];
  bool isLoading = false;
  
  // Admin controller
  late final AdminController _adminController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _adminController = AdminDI.adminController;
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
      final l10n = AppLocalizations.of(context);
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

    final l10n = AppLocalizations.of(context);
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

  // Get stats stream from admin controller
  Stream<Map<String, dynamic>> _getStats() {
    return _adminController.adminStats.stream.map((stats) {
      if (stats == null) {
        return {
          'totalUsers': 0,
          'activeUsers': 0,
          'totalHymns': 0,
          'installations': 0,
        };
      }
      return {
        'totalUsers': stats.totalUsers,
        'activeUsers': stats.activeUsers,
        'totalHymns': stats.totalHymns,
        'installations': stats.installations,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
            onPressed: () {
              HapticFeedback.lightImpact();
              Get.find<ShellController>().toggleDrawer();
            },
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
               onPressed: () {
                 HapticFeedback.lightImpact();
                 Get.to(() => const SuperAdminDashboard());
               },
               tooltip: l10n.superAdminDashboard,
             ),
            if (_tabController.index == 1 && selectedHymns.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _deleteSelectedHymns();
                },
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
               Tab(text: l10n.deletedRecordings),
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
                  const UserManagementScreen(),

                  // Hymns Tab
                  _buildHymnsList(
                      l10n, textColor, primaryColor, backgroundColor),

                  // Deleted Recordings Tab
                  const DeletedRecordingsWidget(),
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
          key: const PageStorageKey('admin_panel_hymns_list'),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: hymns.length,
          itemBuilder: (context, index) {
            final hymn = hymns[index];
            final isSelected = selectedHymns.contains(hymn.id);

            return AdminHymnListItemWidget(
              key: ValueKey(hymn.id),
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
