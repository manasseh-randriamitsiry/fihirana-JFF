import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fihirana/features/admin/data/services/admin_control_service.dart';
import 'package:fihirana/core/utils/version_check_service.dart';
import 'package:fihirana/core/utils/pubspec_service.dart';
import 'package:fihirana/l10n/app_localizations.dart';
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

      setState(() {
        _adminConfig = config;
        _appStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        Get.snackbar(AppLocalizations.of(context)!.error, AppLocalizations.of(context)!.failedToLoadDashboard(e.toString()));
      }
    }
  }

  Future<Map<String, dynamic>> _getAppStats() async {
    try {
      // Get current version
      final currentVersion = await PubspecService.getAppVersion();

      // Get latest available version from GitHub
      String? latestVersion;
      try {
        latestVersion = await _getLatestVersionFromGitHub();
      } catch (e) {
        latestVersion = null;
      }

      // Get user count from Firestore
      final userCount = await _getUserCount();

      return {
        'currentVersion': currentVersion,
        'latestVersion': latestVersion,
        'userCount': userCount,
        'lastConfigUpdate': _adminConfig?.configTimestamp,
      };
    } catch (e) {
      return {};
    }
  }

  Future<int> _getUserCount() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user count: $e');
      }
      return 0;
    }
  }

  Future<String?> _getLatestVersionFromGitHub() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://api.github.com/repos/manasseh-randriamitsiry/fihirana-JFF/releases/latest'),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'Fihirana-JFF-App/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String latestVersion = data['tag_name'].toString().replaceAll('v', '');
        return latestVersion;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching latest version: $e');
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if user has super admin access from Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.accessDenied)),
        body: Center(
          child: Text(AppLocalizations.of(context)!.notLoggedInMessage),
        ),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Check isSuperAdmin from Firestore safely
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final isSuperAdmin = data?['isSuperAdmin'] == true;

          // Fallback to email check for migration
          // HARDCODED DOUBLE CHECK: Allows access even if Firestore fails or field is missing
          final isSuperAdminFallback =
              user.email == 'manassehrandriamitsiry@gmail.com';

          if (!isSuperAdmin && !isSuperAdminFallback) {
            return Scaffold(
              appBar: AppBar(
                title: Text(AppLocalizations.of(context)!.accessDenied),
                backgroundColor: Colors.red.shade900,
                foregroundColor: Colors.white,
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.block, size: 64, color: Colors.red.shade900),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.accessDenied,
                      style:
                          const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.noPermissionAdmin,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(AppLocalizations.of(context)!.back),
                    ),
                  ],
                ),
              ),
            );
          }

          // User has super admin access, show the dashboard
          if (_isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.adminPanel),
              backgroundColor: Colors.red.shade900,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadDashboardData,
                   tooltip: AppLocalizations.of(context)!.refreshDashboard,
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emergency Status Banner
                  if (_adminConfig?.emergencyMode == true)
                    _buildEmergencyBanner(),

                  // Quick Stats
                  _buildQuickStats(),
                  const SizedBox(height: 20),

                  // Update Control Panel
                  _buildUpdateControlPanel(),
                  const SizedBox(height: 20),

                  // Quick Actions Grid
                  _buildQuickActionsGrid(),
                  const SizedBox(height: 20),

                  // Recent Activity
                  _buildRecentActivity(),
                ],
              ),
            ),
          );
        });
  }

  Widget _buildEmergencyBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.red.shade600,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.emergencyModeActive,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.allUpdatesDisabled,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final successText = AppLocalizations.of(context)!.success;
              final clearedText = AppLocalizations.of(context)!.emergencyModeCleared;
              await AdminControlService.clearEmergencyMode();
              await _loadDashboardData();
              if (!mounted) return;
              Get.snackbar(successText, clearedText);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red.shade600,
            ),
            child: Text(AppLocalizations.of(context)!.clearCache),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.appStatistics,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    AppLocalizations.of(context)!.currentVersion,
                    _appStats['currentVersion'] ?? 'Unknown',
                    Icons.info,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    AppLocalizations.of(context)!.latestVersion,
                    _appStats['latestVersion'] ?? 'Unknown',
                    Icons.new_releases,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    AppLocalizations.of(context)!.activeUsers,
                    '${_appStats['userCount'] ?? 0}',
                    Icons.people,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    AppLocalizations.of(context)!.updateStatus,
                    _adminConfig?.updatesEnabled == true
                        ? AppLocalizations.of(context)!.enabled
                        : AppLocalizations.of(context)!.disabled,
                    _adminConfig?.updatesEnabled == true
                        ? Icons.check_circle
                        : Icons.block,
                    _adminConfig?.updatesEnabled == true
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateControlPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.updateControl,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    Get.to(() => const UpdateManagementScreen());
                  },
                  icon: const Icon(Icons.settings),
                  label: Text(AppLocalizations.of(context)!.manage),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Update Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (_adminConfig?.updatesEnabled == true)
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (_adminConfig?.updatesEnabled == true)
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.red.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _adminConfig?.updatesEnabled == true
                        ? Icons.check_circle
                        : Icons.block,
                    color: _adminConfig?.updatesEnabled == true
                        ? Colors.green
                        : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _adminConfig?.updatesEnabled == true 
                              ? AppLocalizations.of(context)!.updatesEnabled
                              : AppLocalizations.of(context)!.updatesDisabled,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _adminConfig?.updatesEnabled == true
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        if (_adminConfig?.adminMessage != null)
                          Text(
                            _adminConfig!.adminMessage!,
                  style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_adminConfig?.blockedVersion != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.versionBlocked(_adminConfig!.blockedVersion!),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.quickActions,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _buildActionButton(
                  AppLocalizations.of(context)!.emergencyStop,
                  Icons.emergency,
                  Colors.red,
                  () async {
                    final emergencyTitle = AppLocalizations.of(context)!.emergencyStop;
                    final emergencyConfirm = AppLocalizations.of(context)!.emergencyStopConfirm;
                    final cancelText = AppLocalizations.of(context)!.cancel;
                    final stopText = AppLocalizations.of(context)!.stop;
                    final successText = AppLocalizations.of(context)!.success;

                    final confirmed = await Get.dialog(
                      AlertDialog(
                        title: Text(emergencyTitle),
                        content: Text(emergencyConfirm),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(cancelText),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.red),
                            child: Text(stopText),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      final stoppedText = emergencyTitle;
                      await AdminControlService.emergencyStop();
                      await _loadDashboardData();
                      if (!mounted) return;
                      Get.snackbar(successText, stoppedText);
                    }
                  },
                ),
                _buildActionButton(
                  AppLocalizations.of(context)!.forceUpdateCheck,
                  Icons.refresh,
                  Colors.blue,
                  () async {
                    final successText = AppLocalizations.of(context)!.success;
                    final checkText = AppLocalizations.of(context)!.checkForUpdates;
                    await VersionCheckService.checkForUpdateManually();
                    if (!mounted) return;
                    Get.snackbar(successText, checkText);
                  },
                ),
                _buildActionButton(
                  AppLocalizations.of(context)!.clearCache,
                  Icons.clear,
                  Colors.orange,
                  () async {
                    final successText = AppLocalizations.of(context)!.success;
                    final clearedText = AppLocalizations.of(context)!.allCacheCleared;
                    await AdminControlService.clearCache();
                    await _loadDashboardData();
                    if (!mounted) return;
                    Get.snackbar(successText, clearedText);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.recentActivity,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_adminConfig?.configTimestamp != null)
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.blue),
                title: Text(AppLocalizations.of(context)!.configurationUpdated),
                subtitle: Text(
                  '${AppLocalizations.of(context)!.lastUpdated}: ${_adminConfig!.configTimestamp!.toString().substring(0, 19)}',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.download, color: Colors.green),
                title: Text(AppLocalizations.of(context)!.updateCheckPerformed),
                subtitle: Text(AppLocalizations.of(context)!.systemCheckCompleted),
              ),
              ListTile(
                leading: const Icon(Icons.info, color: Colors.grey),
                title: Text(AppLocalizations.of(context)!.dashboardLoaded),
                subtitle: Text(AppLocalizations.of(context)!.adminDashboardInitialized),
              ),
          ],
        ),
      ),
    );
  }
}
