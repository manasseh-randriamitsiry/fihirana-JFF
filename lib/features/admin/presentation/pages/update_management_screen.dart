import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/admin/data/services/admin_control_service.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/shared/widgets/common/app_ui.dart';

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
        Get.snackbar(
            AppLocalizations.of(context).error,
            AppLocalizations.of(context)
                .failedToLoadConfiguration(e.toString()));
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
        Get.snackbar(AppLocalizations.of(context).success,
            AppLocalizations.of(context).configurationUpdatedSuccessfully);
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
            AppLocalizations.of(context).error,
            AppLocalizations.of(context)
                .failedToSaveConfiguration(e.toString()));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _emergencyStop() async {
    final emergencyTitle = AppLocalizations.of(context).emergencyStop;
    final emergencyConfirm = AppLocalizations.of(context).emergencyStopConfirm;
    final cancelText = AppLocalizations.of(context).cancel;
    final stopText = AppLocalizations.of(context).emergencyStop;
    final successText = AppLocalizations.of(context).success;
    final stoppedText = AppLocalizations.of(context).emergencyStop;
    final errorTitle = AppLocalizations.of(context).error;
    final errorFn = AppLocalizations.of(context).errorOccurredWithDetails;

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
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
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
    final successText2 = AppLocalizations.of(context).success;
    final clearedText = AppLocalizations.of(context).emergencyModeCleared;
    final errorTitle2 = AppLocalizations.of(context).error;
    final errorFn2 = AppLocalizations.of(context).errorOccurredWithDetails;
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
        title: Text(AppLocalizations.of(context).updateControl),
        actions: [
          if (_currentConfig?.emergencyMode == true)
            IconButton(
              icon: Icon(Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.error),
              onPressed: _clearEmergencyMode,
              tooltip: AppLocalizations.of(context).clearCache,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConfig,
            tooltip: AppLocalizations.of(context).refresh,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            AppSection(
              title: AppLocalizations.of(context).updateControl,
              child: _buildStatusCard(),
            ),
            AppSection(
              title: AppLocalizations.of(context).quickActions,
              child: _buildQuickActions(),
            ),
            AppSection(
              title: AppLocalizations.of(context).configuration,
              child: _buildConfigurationForm(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveConfig,
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isSaving
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context).saving),
                          ],
                        )
                      : Text(AppLocalizations.of(context).saveConfiguration),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final config = _currentConfig!;
    final colors = Theme.of(context).colorScheme;
    final statusColor = config.emergencyMode || !config.updatesEnabled
        ? colors.error
        : colors.primary;

    return AppGroupedSurface(
      children: [
        Padding(
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
                        ? AppLocalizations.of(context).emergencyModeActive
                        : config.updatesEnabled
                            ? AppLocalizations.of(context).updatesEnabled
                            : AppLocalizations.of(context).updatesDisabled,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (config.adminMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.message_outlined,
                          color: colors.onSecondaryContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)
                              .adminMessageLabel(config.adminMessage!),
                          style: TextStyle(color: colors.onSecondaryContainer),
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
                    color: colors.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.block_outlined,
                          color: colors.onErrorContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)
                              .blockedVersionLabel(config.blockedVersion!),
                          style: TextStyle(color: colors.onErrorContainer),
                        ),
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

  Widget _buildQuickActions() {
    final colors = Theme.of(context).colorScheme;
    return AppGroupedSurface(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _emergencyStop,
                      icon: Icon(Icons.emergency_outlined, color: colors.error),
                      label: Text(AppLocalizations.of(context).emergencyStop),
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.errorContainer,
                        foregroundColor: colors.onErrorContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () async {
                        final successText =
                            AppLocalizations.of(context).success;
                        final clearedText =
                            AppLocalizations.of(context).allCacheCleared;
                        await AdminControlService.clearCache();
                        if (!mounted) return;
                        Get.snackbar(successText, clearedText);
                      },
                      icon: const Icon(Icons.cleaning_services_outlined),
                      label: Text(AppLocalizations.of(context).clearCache),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfigurationForm() {
    final config = _currentConfig!;

    return AppGroupedSurface(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toggle Switches
              SwitchListTile(
                title: Text(AppLocalizations.of(context).enableUpdates),
                subtitle: Text(
                    AppLocalizations.of(context).allowUsersToDownloadUpdates),
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
                title: Text(AppLocalizations.of(context).forceUpdate),
                subtitle: Text(AppLocalizations.of(context).forceUsersToUpdate),
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
                  labelText: AppLocalizations.of(context).blockedVersion,
                  hintText: AppLocalizations.of(context).versionEG,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.block),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _minVersionController,
                decoration: InputDecoration(
                  labelText:
                      AppLocalizations.of(context).minimumSupportedVersion,
                  hintText: AppLocalizations.of(context).versionEG,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.verified),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _recommendedVersionController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).recommendedVersion,
                  hintText: AppLocalizations.of(context).versionEG,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.thumb_up),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _allowedVersionsController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).allowedVersions,
                  hintText: AppLocalizations.of(context).versionsEG,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.list),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _adminMessageController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).adminMessage,
                  hintText:
                      AppLocalizations.of(context).messageToDisplayToAllUsers,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.message),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ],
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
