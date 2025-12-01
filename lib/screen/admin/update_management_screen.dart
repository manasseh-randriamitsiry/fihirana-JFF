import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/services/features/admin_control_service.dart';
import 'package:fihirana/l10n/app_localizations.dart';

class UpdateManagementScreen extends StatefulWidget {
  const UpdateManagementScreen({super.key});

  @override
  State<UpdateManagementScreen> createState() => _UpdateManagementScreenState();
}

class _UpdateManagementScreenState extends State<UpdateManagementScreen> {
  final TextEditingController _blockedVersionController =
      TextEditingController();
  final TextEditingController _minVersionController = TextEditingController();
  final TextEditingController _recommendedVersionController =
      TextEditingController();
  final TextEditingController _adminMessageController = TextEditingController();
  final TextEditingController _allowedVersionsController =
      TextEditingController();

  AdminConfig? _currentConfig;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    try {
      final config = await AdminControlService.fetchAdminConfig();
      setState(() {
        _currentConfig = config;
        _blockedVersionController.text = config.blockedVersion ?? '';
        _minVersionController.text = config.minSupportedVersion ?? '';
        _recommendedVersionController.text = config.recommendedVersion ?? '';
        _adminMessageController.text = config.adminMessage ?? '';
        _allowedVersionsController.text = config.allowedVersions.join(', ');
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar('Error', 'Failed to load configuration: $e');
    }
  }

  Future<void> _saveConfig() async {
    if (_currentConfig == null) return;

    setState(() => _isSaving = true);
    try {
      final allowedVersionsList = _allowedVersionsController.text
          .split(',')
          .map((v) => v.trim())
          .where((v) => v.isNotEmpty)
          .toList();

      final updatedConfig = AdminConfig(
        updatesEnabled: _currentConfig!.updatesEnabled,
        forceUpdate: _currentConfig!.forceUpdate,
        emergencyMode: _currentConfig!.emergencyMode,
        blockedVersion: _blockedVersionController.text.isEmpty
            ? null
            : _blockedVersionController.text.trim(),
        minSupportedVersion: _minVersionController.text.isEmpty
            ? null
            : _minVersionController.text.trim(),
        recommendedVersion: _recommendedVersionController.text.isEmpty
            ? null
            : _recommendedVersionController.text.trim(),
        adminMessage: _adminMessageController.text.isEmpty
            ? null
            : _adminMessageController.text.trim(),
        allowedVersions: allowedVersionsList,
        configTimestamp: DateTime.now(),
      );

      await AdminControlService.setAdminConfig(updatedConfig);
      await _loadConfig(); // Reload to confirm
      Get.snackbar('Success', 'Configuration updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to save configuration: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _emergencyStop() async {
    final confirmed = await Get.dialog(
      AlertDialog(
        title: Text(AppLocalizations.of(context)!.emergencyStop),
        content: Text(
          AppLocalizations.of(context)!.emergencyStopConfirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.emergencyStop),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AdminControlService.emergencyStop();
        await _loadConfig();
        if (context.mounted) {
          Get.snackbar(AppLocalizations.of(context)!.success, AppLocalizations.of(context)!.emergencyStop);
        }
      } catch (e) {
        if (context.mounted) {
          Get.snackbar(AppLocalizations.of(context)!.error, AppLocalizations.of(context)!.errorOccurredWithDetails(e.toString()));
        }
      }
    }
  }

  Future<void> _clearEmergencyMode() async {
    try {
      await AdminControlService.clearEmergencyMode();
      await _loadConfig();
      if (context.mounted) {
        Get.snackbar(AppLocalizations.of(context)!.success, AppLocalizations.of(context)!.emergencyModeCleared);
      }
    } catch (e) {
      if (context.mounted) {
        Get.snackbar(AppLocalizations.of(context)!.error, AppLocalizations.of(context)!.errorOccurredWithDetails(e.toString()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.updateControl),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (_currentConfig?.emergencyMode == true)
            IconButton(
              icon: const Icon(Icons.warning, color: Colors.yellow),
              onPressed: _clearEmergencyMode,
              tooltip: AppLocalizations.of(context)!.clearCache,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConfig,
            tooltip: AppLocalizations.of(context)!.refresh,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            _buildStatusCard(),
            const SizedBox(height: 20),

            // Quick Actions
            _buildQuickActions(),
            const SizedBox(height: 20),

            // Configuration Form
            _buildConfigurationForm(),
            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveConfig,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(AppLocalizations.of(context)!.saving),
                        ],
                      )
                    : Text(AppLocalizations.of(context)!.saveConfiguration),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final config = _currentConfig!;
    final statusColor = config.emergencyMode
        ? Colors.red
        : config.updatesEnabled
            ? Colors.green
            : Colors.orange;

    return Card(
      color: statusColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  config.emergencyMode
                      ? Icons.warning
                      : config.updatesEnabled
                          ? Icons.check_circle
                          : Icons.error,
                  color: statusColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  config.emergencyMode
                      ? 'Emergency Mode Active'
                      : config.updatesEnabled
                          ? 'Updates Enabled'
                          : 'Updates Disabled',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (config.adminMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.message, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Admin Message: ${config.adminMessage}',
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            if (config.blockedVersion != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.block, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Blocked Version: ${config.blockedVersion}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _emergencyStop,
                    icon: const Icon(Icons.emergency),
                    label: Text(AppLocalizations.of(context)!.emergencyStop),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await AdminControlService.clearCache();
                      if (context.mounted) {
                        Get.snackbar(AppLocalizations.of(context)!.success, AppLocalizations.of(context)!.allCacheCleared);
                      }
                    },
                    icon: const Icon(Icons.clear),
                    label: Text(AppLocalizations.of(context)!.clearCache),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationForm() {
    final config = _currentConfig!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Toggle Switches
            SwitchListTile(
              title: Text(AppLocalizations.of(context)!.enableUpdates),
              subtitle: Text(AppLocalizations.of(context)!.allowUsersToDownloadUpdates),
              value: config.updatesEnabled,
              onChanged: (value) {
                setState(() {
                  _currentConfig = AdminConfig(
                    updatesEnabled: value,
                    forceUpdate: config.forceUpdate,
                    emergencyMode: config.emergencyMode,
                    blockedVersion: config.blockedVersion,
                    minSupportedVersion: config.minSupportedVersion,
                    recommendedVersion: config.recommendedVersion,
                    adminMessage: config.adminMessage,
                    allowedVersions: config.allowedVersions,
                  );
                });
              },
            ),
            SwitchListTile(
              title: Text(AppLocalizations.of(context)!.forceUpdate),
              subtitle: Text(AppLocalizations.of(context)!.forceUsersToUpdate),
              value: config.forceUpdate,
              onChanged: (value) {
                setState(() {
                  _currentConfig = AdminConfig(
                    updatesEnabled: config.updatesEnabled,
                    forceUpdate: value,
                    emergencyMode: config.emergencyMode,
                    blockedVersion: config.blockedVersion,
                    minSupportedVersion: config.minSupportedVersion,
                    recommendedVersion: config.recommendedVersion,
                    adminMessage: config.adminMessage,
                    allowedVersions: config.allowedVersions,
                  );
                });
              },
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Text Fields
            TextFormField(
              controller: _blockedVersionController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.blockedVersion,
                hintText: AppLocalizations.of(context)!.versionEG,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.block),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _minVersionController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.minimumSupportedVersion,
                hintText: AppLocalizations.of(context)!.versionEG,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.verified),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _recommendedVersionController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.recommendedVersion,
                hintText: AppLocalizations.of(context)!.versionEG,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.thumb_up),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _allowedVersionsController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.allowedVersions,
                hintText: AppLocalizations.of(context)!.versionsEG,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.list),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _adminMessageController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.adminMessage,
                hintText: AppLocalizations.of(context)!.messageToDisplayToAllUsers,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.message),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _blockedVersionController.dispose();
    _minVersionController.dispose();
    _recommendedVersionController.dispose();
    _adminMessageController.dispose();
    _allowedVersionsController.dispose();
    super.dispose();
  }
}
