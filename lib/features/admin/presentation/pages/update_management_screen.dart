import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/admin/data/services/admin_control_service.dart';
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
      if (mounted) {
        Get.snackbar(AppLocalizations.of(context)!.error, AppLocalizations.of(context)!.failedToLoadConfiguration(e.toString()));
      }
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
      if (mounted) {
        Get.snackbar(AppLocalizations.of(context)!.success, AppLocalizations.of(context)!.configurationUpdatedSuccessfully);
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(AppLocalizations.of(context)!.error, AppLocalizations.of(context)!.failedToSaveConfiguration(e.toString()));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _emergencyStop() async {
    final emergencyTitle = AppLocalizations.of(context)!.emergencyStop;
    final emergencyConfirm = AppLocalizations.of(context)!.emergencyStopConfirm;
    final cancelText = AppLocalizations.of(context)!.cancel;
    final stopText = AppLocalizations.of(context)!.emergencyStop;
    final successText = AppLocalizations.of(context)!.success;
    final stoppedText = AppLocalizations.of(context)!.emergencyStop;
    final errorTitle = AppLocalizations.of(context)!.error;
    final errorFn = AppLocalizations.of(context)!.errorOccurredWithDetails;

    final confirmed = await Get.dialog(
      AlertDialog(
        title: Text(emergencyTitle),
        content: Text(
          emergencyConfirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(stopText),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AdminControlService.emergencyStop();
        await _loadConfig();
        if (!mounted) return;
        Get.snackbar(successText, stoppedText);
      } catch (e) {
        if (!mounted) return;
        Get.snackbar(errorTitle, errorFn(e.toString()));
      }
    }
  }

  Future<void> _clearEmergencyMode() async {
    final successText2 = AppLocalizations.of(context)!.success;
    final clearedText = AppLocalizations.of(context)!.emergencyModeCleared;
    final errorTitle2 = AppLocalizations.of(context)!.error;
    final errorFn2 = AppLocalizations.of(context)!.errorOccurredWithDetails;
    try {
      await AdminControlService.clearEmergencyMode();
      await _loadConfig();
      if (!mounted) return;
      Get.snackbar(successText2, clearedText);
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(errorTitle2, errorFn2(e.toString()));
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
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
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
                       ? AppLocalizations.of(context)!.emergencyModeActive
                       : config.updatesEnabled
                           ? AppLocalizations.of(context)!.updatesEnabled
                           : AppLocalizations.of(context)!.updatesDisabled,
                   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                           AppLocalizations.of(context)!.adminMessageLabel(config.adminMessage!),
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
                         AppLocalizations.of(context)!.blockedVersionLabel(config.blockedVersion!),
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
             Text(
               AppLocalizations.of(context)!.quickActions,
               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      final successText = AppLocalizations.of(context)!.success;
                      final clearedText = AppLocalizations.of(context)!.allCacheCleared;
                      await AdminControlService.clearCache();
                      if (!mounted) return;
                      Get.snackbar(successText, clearedText);
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
             Text(
               AppLocalizations.of(context)!.configuration,
               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.block),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _minVersionController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.minimumSupportedVersion,
                hintText: AppLocalizations.of(context)!.versionEG,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.verified),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _recommendedVersionController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.recommendedVersion,
                hintText: AppLocalizations.of(context)!.versionEG,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.thumb_up),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _allowedVersionsController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.allowedVersions,
                hintText: AppLocalizations.of(context)!.versionsEG,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.list),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _adminMessageController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.adminMessage,
                hintText: AppLocalizations.of(context)!.messageToDisplayToAllUsers,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.message),
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
