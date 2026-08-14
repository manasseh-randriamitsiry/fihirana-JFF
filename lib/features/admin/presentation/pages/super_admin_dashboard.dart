import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'package:fihirana/core/utils/pubspec_service.dart';
import 'package:fihirana/core/utils/version_check_service.dart';
import 'package:fihirana/features/admin/data/services/admin_control_service.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/shared/widgets/common/app_ui.dart';

import 'update_management_screen.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  AdminConfig? _adminConfig;
  bool _isLoading = true;
  Map<String, dynamic> _appStats = {};

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final config = await AdminControlService.fetchAdminConfig();
      final stats = await _getAppStats();
      if (!mounted) return;
      setState(() {
        _adminConfig = config;
        _appStats = stats;
        _isLoading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        Get.snackbar(
          AppLocalizations.of(context).error,
          AppLocalizations.of(context).failedToLoadDashboard(error.toString()),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _getAppStats() async {
    try {
      final currentVersion = await PubspecService.getAppVersion();
      String? latestVersion;
      try {
        latestVersion = await _getLatestVersionFromGitHub();
      } catch (_) {
        latestVersion = null;
      }
      final userCount = await _getUserCount();

      return {
        'currentVersion': currentVersion,
        'latestVersion': latestVersion,
        'userCount': userCount,
        'lastConfigUpdate': _adminConfig?.configTimestamp,
      };
    } catch (_) {
      return {};
    }
  }

  Future<int> _getUserCount() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').count().get();
      return snapshot.count ?? 0;
    } catch (error) {
      if (kDebugMode) debugPrint('Error getting user count: $error');
      return 0;
    }
  }

  Future<String?> _getLatestVersionFromGitHub() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.github.com/repos/manasseh-randriamitsiry/fihirana-JFF/releases/latest',
        ),
        headers: const {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'Fihirana-JFF-App/1.0',
        },
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['tag_name'].toString().replaceAll('v', '');
      }
    } catch (error) {
      if (kDebugMode) debugPrint('Error fetching latest version: $error');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return AppPageScaffold(
        title: l10n.accessDenied,
        body: AppEmptyState(
          icon: Icons.lock_outline_rounded,
          title: l10n.accessDenied,
          message: l10n.notLoggedInMessage,
        ),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppPageScaffold(
            title: l10n.adminPanel,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final isSuperAdmin = data?['isSuperAdmin'] == true;
        final isSuperAdminFallback =
            user.email == 'manassehrandriamitsiry@gmail.com';
        if (!isSuperAdmin && !isSuperAdminFallback) {
          return AppPageScaffold(
            title: l10n.accessDenied,
            body: AppEmptyState(
              icon: Icons.block_rounded,
              title: l10n.accessDenied,
              message: l10n.noPermissionAdmin,
              action: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.back),
              ),
            ),
          );
        }

        if (_isLoading) {
          return AppPageScaffold(
            title: l10n.adminPanel,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return AppPageScaffold(
          title: l10n.adminPanel,
          actions: [
            IconButton(
              tooltip: l10n.refreshDashboard,
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              if (_adminConfig?.emergencyMode == true) _buildEmergencyBanner(),
              AppSection(
                title: l10n.appStatistics,
                child: _buildQuickStats(),
              ),
              AppSection(
                title: l10n.updateControl,
                child: _buildUpdateControlPanel(),
              ),
              AppSection(
                title: l10n.quickActions,
                child: _buildQuickActionsGrid(),
              ),
              AppSection(
                title: l10n.recentActivity,
                child: _buildRecentActivity(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmergencyBanner() {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.error.withValues(alpha: .45)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: colors.error, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.emergencyModeActive,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colors.onErrorContainer,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.allUpdatesDisabled,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onErrorContainer,
                          ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () async {
                        await AdminControlService.clearEmergencyMode();
                        await _loadDashboardData();
                        if (mounted) {
                          Get.snackbar(l10n.success, l10n.emergencyModeCleared);
                        }
                      },
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: Text(l10n.clearCache),
                      style: TextButton.styleFrom(
                        foregroundColor: colors.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final updatesEnabled = _adminConfig?.updatesEnabled == true;
    final stats = [
      _DashboardStat(
        title: l10n.currentVersion,
        value: _appStats['currentVersion'] ?? '—',
        icon: Icons.info_outline_rounded,
        foreground: colors.primary,
        background: colors.primaryContainer,
      ),
      _DashboardStat(
        title: l10n.latestVersion,
        value: _appStats['latestVersion'] ?? '—',
        icon: Icons.new_releases_outlined,
        foreground: colors.secondary,
        background: colors.secondaryContainer,
      ),
      _DashboardStat(
        title: l10n.activeUsers,
        value: '${_appStats['userCount'] ?? 0}',
        icon: Icons.people_outline_rounded,
        foreground: colors.tertiary,
        background: colors.tertiaryContainer,
      ),
      _DashboardStat(
        title: l10n.updateStatus,
        value: updatesEnabled ? l10n.enabled : l10n.disabled,
        icon: updatesEnabled
            ? Icons.check_circle_outline_rounded
            : Icons.block_outlined,
        foreground: updatesEnabled ? colors.primary : colors.error,
        background:
            updatesEnabled ? colors.primaryContainer : colors.errorContainer,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 2 : 1;
        final itemWidth =
            (constraints.maxWidth - (columns == 2 ? 10 : 0)) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final stat in stats)
              SizedBox(width: itemWidth, child: _buildStatCard(stat)),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(_DashboardStat stat) {
    return AppGroupedSurface(
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: stat.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(stat.icon, color: stat.foreground, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat.title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      stat.value,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: stat.foreground,
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateControlPanel() {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final updatesEnabled = _adminConfig?.updatesEnabled == true;
    final statusColor = updatesEnabled ? colors.primary : colors.error;

    return AppGroupedSurface(
      children: [
        AppListRow(
          icon: updatesEnabled
              ? Icons.check_circle_outline_rounded
              : Icons.block_outlined,
          iconColor: statusColor,
          title: updatesEnabled ? l10n.updatesEnabled : l10n.updatesDisabled,
          subtitle: _adminConfig?.adminMessage,
          onTap: () => Get.to(() => const UpdateManagementScreen()),
        ),
        const AppGroupDivider(),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: () => Get.to(() => const UpdateManagementScreen()),
              icon: const Icon(Icons.tune_rounded),
              label: Text(l10n.manage),
            ),
          ),
        ),
        if (_adminConfig?.blockedVersion != null) ...[
          const AppGroupDivider(),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.tertiaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: colors.onTertiaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.versionBlocked(_adminConfig!.blockedVersion!),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onTertiaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickActionsGrid() {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final actions = [
      _DashboardAction(
        title: l10n.emergencyStop,
        icon: Icons.emergency_outlined,
        foreground: colors.error,
        background: colors.errorContainer,
        onPressed: _confirmEmergencyStop,
      ),
      _DashboardAction(
        title: l10n.forceUpdateCheck,
        icon: Icons.refresh_rounded,
        foreground: colors.primary,
        background: colors.primaryContainer,
        onPressed: _forceUpdateCheck,
      ),
      _DashboardAction(
        title: l10n.clearCache,
        icon: Icons.delete_sweep_outlined,
        foreground: colors.tertiary,
        background: colors.tertiaryContainer,
        onPressed: _clearCache,
      ),
    ];

    return AppGroupedSurface(
      padding: const EdgeInsets.all(12),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 560
                ? 3
                : constraints.maxWidth >= 360
                    ? 2
                    : 1;
            final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final action in actions)
                  SizedBox(
                    width: width,
                    child: _buildActionButton(action),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(_DashboardAction action) {
    return Material(
      color: action.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: action.onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 96),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(action.icon, color: action.foreground, size: 26),
                const SizedBox(height: 8),
                Text(
                  action.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: action.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmEmergencyStop() async {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(l10n.emergencyStop),
        content: Text(l10n.emergencyStopConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: colors.error),
            child: Text(l10n.stop),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await AdminControlService.emergencyStop();
    await _loadDashboardData();
    if (mounted) Get.snackbar(l10n.success, l10n.emergencyStop);
  }

  Future<void> _forceUpdateCheck() async {
    final l10n = AppLocalizations.of(context);
    await VersionCheckService.checkForUpdateManually();
    if (mounted) Get.snackbar(l10n.success, l10n.checkForUpdates);
  }

  Future<void> _clearCache() async {
    final l10n = AppLocalizations.of(context);
    await AdminControlService.clearCache();
    await _loadDashboardData();
    if (mounted) Get.snackbar(l10n.success, l10n.allCacheCleared);
  }

  Widget _buildRecentActivity() {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return AppGroupedSurface(
      children: [
        if (_adminConfig?.configTimestamp != null) ...[
          AppListRow(
            icon: Icons.settings_outlined,
            iconColor: colors.primary,
            title: l10n.configurationUpdated,
            subtitle:
                '${l10n.lastUpdated}: ${_adminConfig!.configTimestamp!.toString().substring(0, 19)}',
            trailing: const SizedBox.shrink(),
          ),
          const AppGroupDivider(),
        ],
        AppListRow(
          icon: Icons.download_outlined,
          iconColor: colors.secondary,
          title: l10n.updateCheckPerformed,
          subtitle: l10n.systemCheckCompleted,
          trailing: const SizedBox.shrink(),
        ),
        const AppGroupDivider(),
        AppListRow(
          icon: Icons.info_outline_rounded,
          iconColor: colors.onSurfaceVariant,
          title: l10n.dashboardLoaded,
          subtitle: l10n.adminDashboardInitialized,
          trailing: const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _DashboardStat {
  final String title;
  final String value;
  final IconData icon;
  final Color foreground;
  final Color background;

  const _DashboardStat({
    required this.title,
    required this.value,
    required this.icon,
    required this.foreground,
    required this.background,
  });
}

class _DashboardAction {
  final String title;
  final IconData icon;
  final Color foreground;
  final Color background;
  final Future<void> Function() onPressed;

  const _DashboardAction({
    required this.title,
    required this.icon,
    required this.foreground,
    required this.background,
    required this.onPressed,
  });
}
