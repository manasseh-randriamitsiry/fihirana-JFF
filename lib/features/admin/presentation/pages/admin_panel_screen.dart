import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/hymn/data/services/hymn_service.dart';
import './user_management_screen.dart';
import './super_admin_dashboard.dart';
import 'package:fihirana/core/navigation/shell_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/features/auth/presentation/controllers/auth_controller.dart';
import 'package:fihirana/shared/widgets/common/skeleton_admin_list.dart';
import 'package:fihirana/features/admin/presentation/widgets/admin_stats_widgets.dart';
import 'package:fihirana/features/admin/presentation/widgets/admin_hymn_widgets.dart';
import 'package:fihirana/features/admin/presentation/widgets/deleted_recordings_widget.dart';
import 'package:fihirana/features/admin/presentation/controllers/admin_controller.dart';
import 'package:fihirana/features/admin/di/admin_di.dart';
import 'package:fihirana/core/design_system/app_scale.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  final HymnService _hymnService = HymnService();
  late TabController _tabController;
  List<String> selectedHymns = [];
  bool isLoading = false;

  /// Subscribed once: a new stream instance per build() makes StreamBuilder
  /// tear down and re-open the Firestore listener on every tab tap, which
  /// flashes the skeleton list in place of the hymns.
  late final Stream<List<Hymn>> _hymnsStream;

  // Admin controller
  AdminController? _adminController;
  bool _authorized = false;
  Worker? _permissionWorker;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _hymnsStream = _hymnService.getFirebaseHymnsStream();
    _checkAdminAccess();
  }

  @override
  void dispose() {
    _permissionWorker?.call();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminAccess() async {
    // isAdmin stays false until Firestore answers, so the panel must not be
    // built - or its controller resolved - before that snapshot arrives.
    final auth = Get.find<AuthController>();
    if (!auth.isPermissionResolved) {
      final resolved = Completer<void>();
      _permissionWorker = ever<bool>(auth.permissionResolved, (value) {
        if (value && !resolved.isCompleted) resolved.complete();
      });
      await resolved.future
          .timeout(const Duration(seconds: 5), onTimeout: () {});
      if (!mounted) return;
    }

    if (auth.isAdmin) {
      setState(() {
        _authorized = true;
        _adminController = AdminDI.adminController;
      });
      return;
    }

    final l10n = AppLocalizations.of(context);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.noAdminPermission),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
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
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.error}: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  // Get stats stream from admin controller
  Stream<Map<String, dynamic>> _getStats() {
    return _adminController!.adminStats.stream.map((stats) {
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
    if (!_authorized) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).adminPanel),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          icon: const Icon(Icons.menu_rounded),
          onPressed: () {
            HapticFeedback.lightImpact();
            Get.find<ShellController>().toggleDrawer();
          },
        ),
        title: Text(
          l10n.adminPanel,
        ),
        actions: [
          IconButton(
            icon:
                Icon(Icons.admin_panel_settings_outlined, color: colors.error),
            onPressed: () {
              HapticFeedback.lightImpact();
              Get.to(() => const SuperAdminDashboard());
            },
            tooltip: l10n.superAdminDashboard,
          ),
          if (_tabController.index == 1 && selectedHymns.isNotEmpty)
            IconButton(
              tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
              icon: Icon(Icons.delete_outline_rounded, color: colors.error),
              onPressed: () {
                HapticFeedback.lightImpact();
                _deleteSelectedHymns();
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) => setState(() {}), // Rebuild to show/hide actions
          tabs: [
            Tab(text: l10n.userManagement), // Reuse string or add "Users"
            Tab(text: l10n.hymns), // Reuse string or add "Hymns"
            Tab(text: l10n.deletedRecordings),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
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
                  _buildHymnsList(l10n),

                  // Deleted Recordings Tab
                  const DeletedRecordingsWidget(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHymnsList(AppLocalizations l10n) {
    return StreamBuilder<List<Hymn>>(
      stream: _hymnsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('${l10n.error}: ${snapshot.error}'));
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
          padding: const EdgeInsets.symmetric(
              horizontal: AppScale.space16, vertical: AppScale.space12),
          itemCount: hymns.length,
          itemBuilder: (context, index) {
            final hymn = hymns[index];
            final isSelected = selectedHymns.contains(hymn.id);

            return AdminHymnListItemWidget(
              key: ValueKey(hymn.id),
              hymn: hymn,
              isSelected: isSelected,
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
