import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:fihirana/app/theme/color_controller.dart';

class PermissionRequestDialog extends StatefulWidget {
  final VoidCallback onPermissionsGranted;

  const PermissionRequestDialog({
    super.key,
    required this.onPermissionsGranted,
  });

  @override
  State<PermissionRequestDialog> createState() => _PermissionRequestDialogState();
}

class _PermissionRequestDialogState extends State<PermissionRequestDialog> {
  bool _notificationGranted = false;
  bool _installPackagesGranted = false;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentPermissions();
  }

  Future<void> _checkCurrentPermissions() async {
    final notificationStatus = await AwesomeNotifications().isNotificationAllowed();
    final installPackagesStatus = await Permission.requestInstallPackages.status;

    setState(() {
      _notificationGranted = notificationStatus;
      _installPackagesGranted = installPackagesStatus.isGranted;
    });
  }

  Future<void> _requestPermissions() async {
    setState(() => _isRequesting = true);

    try {
      // Request notification permission
      if (!_notificationGranted) {
        final notificationAllowed = await AwesomeNotifications().requestPermissionToSendNotifications();
        setState(() => _notificationGranted = notificationAllowed);
      }

      // Request package installation permission
      if (!_installPackagesGranted) {
        final installStatus = await Permission.requestInstallPackages.request();
        setState(() => _installPackagesGranted = installStatus.isGranted);
      }

      // Check if all permissions are granted
      if (_notificationGranted && _installPackagesGranted) {
        widget.onPermissionsGranted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error requesting permissions: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Dialog(
      backgroundColor: colorController.backgroundColor.value,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: isTablet ? 80 : 60,
              height: isTablet ? 80 : 60,
              decoration: BoxDecoration(
                color: colorController.primaryColor.value.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.security_rounded,
                size: isTablet ? 40 : 30,
                color: colorController.primaryColor.value,
              ),
            ),

            SizedBox(height: isTablet ? 24 : 16),

            // Title
            Text(
              'App Permissions',
              style: TextStyle(
                fontSize: isTablet ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: colorController.textColor.value,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: isTablet ? 16 : 12),

            // Description
            Text(
              'To provide the best experience, we need the following permissions:',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: colorController.textColor.value.withValues(alpha: 0.7),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: isTablet ? 24 : 20),

            // Permission items
            const SizedBox(height: 8),
            _buildPermissionItem(
              context,
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              description: 'Receive daily verses, announcements, and update notifications',
              isGranted: _notificationGranted,
              isTablet: isTablet,
            ),

            SizedBox(height: isTablet ? 16 : 12),

            _buildPermissionItem(
              context,
              icon: Icons.system_update_rounded,
              title: 'Install Packages',
              description: 'Allow app updates to be installed automatically',
              isGranted: _installPackagesGranted,
              isTablet: isTablet,
            ),

            SizedBox(height: isTablet ? 32 : 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Skip for now',
                      style: TextStyle(
                        color: colorController.textColor.value.withValues(alpha: 0.6),
                        fontSize: isTablet ? 16 : 14,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isTablet ? 16 : 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _isRequesting ? null : _requestPermissions,
                    style: FilledButton.styleFrom(
                      backgroundColor: colorController.primaryColor.value,
                      padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isRequesting
                        ? SizedBox(
                            width: isTablet ? 20 : 16,
                            height: isTablet ? 20 : 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorController.backgroundColor.value,
                            ),
                          )
                        : Text(
                            'Grant Permissions',
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.w600,
                            ),
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

  Widget _buildPermissionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required bool isTablet,
  }) {
    final colorController = Get.find<ColorController>();

    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: colorController.backgroundColor.value,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGranted
              ? colorController.primaryColor.value.withValues(alpha: 0.3)
              : colorController.textColor.value.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 12 : 8),
            decoration: BoxDecoration(
              color: isGranted
                  ? colorController.primaryColor.value.withValues(alpha: 0.1)
                  : colorController.textColor.value.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: isTablet ? 24 : 20,
              color: isGranted
                  ? colorController.primaryColor.value
                  : colorController.textColor.value.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w600,
                        color: colorController.textColor.value,
                      ),
                    ),
                    if (isGranted) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.check_circle_rounded,
                        size: isTablet ? 18 : 16,
                        color: Colors.green,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    color: colorController.textColor.value.withValues(alpha: 0.6),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}