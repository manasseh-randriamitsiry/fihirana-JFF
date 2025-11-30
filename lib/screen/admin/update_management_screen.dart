import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/services/features/admin_control_service.dart';

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
        title: const Text('Emergency Stop'),
        content: const Text(
          'This will immediately disable all updates for all users. '
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Emergency Stop'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AdminControlService.emergencyStop();
        await _loadConfig();
        Get.snackbar('Success', 'Emergency stop activated');
      } catch (e) {
        Get.snackbar('Error', 'Failed to activate emergency stop: $e');
      }
    }
  }

  Future<void> _clearEmergencyMode() async {
    try {
      await AdminControlService.clearEmergencyMode();
      await _loadConfig();
      Get.snackbar('Success', 'Emergency mode cleared');
    } catch (e) {
      Get.snackbar('Error', 'Failed to clear emergency mode: $e');
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
        title: const Text('Update Management'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (_currentConfig?.emergencyMode == true)
            IconButton(
              icon: const Icon(Icons.warning, color: Colors.yellow),
              onPressed: _clearEmergencyMode,
              tooltip: 'Clear Emergency Mode',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConfig,
            tooltip: 'Refresh',
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
                    ? const Row(
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
                          Text('Saving...'),
                        ],
                      )
                    : const Text('Save Configuration'),
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
                    label: const Text('Emergency Stop'),
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
                      Get.snackbar('Success', 'Cache cleared');
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear Cache'),
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
              title: const Text('Enable Updates'),
              subtitle: const Text('Allow users to download updates'),
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
              title: const Text('Force Update'),
              subtitle: const Text('Force users to update when available'),
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
              decoration: const InputDecoration(
                labelText: 'Blocked Version',
                hintText: 'e.g., 1.0.15',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.block),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _minVersionController,
              decoration: const InputDecoration(
                labelText: 'Minimum Supported Version',
                hintText: 'e.g., 1.0.10',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.verified),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _recommendedVersionController,
              decoration: const InputDecoration(
                labelText: 'Recommended Version',
                hintText: 'e.g., 1.0.20',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.thumb_up),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _allowedVersionsController,
              decoration: const InputDecoration(
                labelText: 'Allowed Versions',
                hintText: 'e.g., 1.0.10, 1.0.11, 1.0.12',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.list),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _adminMessageController,
              decoration: const InputDecoration(
                labelText: 'Admin Message',
                hintText: 'Message to display to all users',
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
