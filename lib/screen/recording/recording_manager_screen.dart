import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:fihirana/controller/recording_controller.dart';
import 'package:fihirana/controller/color_controller.dart';
import 'package:fihirana/controller/shell_controller.dart';
import 'package:fihirana/widgets/context_aware_fab.dart';
import 'package:fihirana/widgets/recording/recording_tile_widget.dart';
import 'package:fihirana/services/security_service.dart';
import 'standalone_recording_screen.dart';

class RecordingManagerScreen extends StatelessWidget {
  const RecordingManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Get.find to get existing controller or create if not exists
    final RecordingController controller =
        Get.isRegistered<RecordingController>()
            ? Get.find<RecordingController>()
            : Get.put(RecordingController(), permanent: true);
    final ColorController colorController = Get.find<ColorController>();

    // Auto-refresh when page is accessed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.onPageVisible();
    });

    // Auto-refresh when page is accessed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.onPageVisible();
    });

    return Scaffold(
      backgroundColor: colorController.backgroundColor.value,
      appBar: AppBar(
        backgroundColor: colorController.backgroundColor.value,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.menu_rounded, color: colorController.iconColor.value),
          onPressed: () => Get.find<ShellController>().toggleDrawer(),
        ),
        title: Text(
          'Recordings',
          style: TextStyle(
            color: colorController.textColor.value,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: colorController.iconColor.value,
            ),
            tooltip: 'Refresh recordings',
            onPressed: () => controller.refreshRecordings(),
          ),
          Obx(() {
            if (controller.isDriveSignedIn.value) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.sync,
                      color: colorController.iconColor.value,
                    ),
                    tooltip: 'Sync from Google Drive',
                    onPressed: () => controller.syncFromDrive(),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.cloud_done,
                      color: colorController.iconColor.value,
                    ),
                    tooltip: 'Signed in as ${controller.userEmail.value}',
                    onPressed: () {
                      _showDriveDialog(context, controller, colorController);
                    },
                  ),
                ],
              );
            } else {
              return IconButton(
                icon: Icon(
                  Icons.cloud_upload_outlined,
                  color: colorController.iconColor.value,
                ),
                tooltip: 'Sign in to Google Drive',
                onPressed: () => controller.signInToDrive(),
              );
            }
          }),
        ],
      ),
      body: Obx(() {
        // Security check - prevent banned users from accessing recordings
        final SecurityService securityService = SecurityService.instance;
        if (securityService.isSecurityChecked &&
            securityService.isUserBlocked) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.block,
                  size: 80,
                  color: Colors.red.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Access Restricted',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your account has been restricted from recording features.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red.withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.warning_amber,
                          color: Colors.orange, size: 24),
                      const SizedBox(height: 8),
                      Text(
                        securityService.blockReason.isNotEmpty
                            ? securityService.blockReason
                            : 'Account suspended',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final personalRecordings =
            controller.recordings.where((r) => !r.isPublic).toList();
        // Load community public recordings from Firestore
        final publicRecordings = controller.publicRecordings.toList();

        // Debug: Print current state
        if (kDebugMode) {
          print(
              'RecordingManager: Total recordings: ${controller.recordings.length}');
          print(
              'RecordingManager: Personal: ${personalRecordings.length}, Public: ${publicRecordings.length}');
        }

        if (personalRecordings.isEmpty && publicRecordings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mic_off_rounded,
                  size: 80,
                  color: colorController.iconColor.value.withValues(alpha: 0.3),
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 16),
                Text(
                  'No recordings yet',
                  style: TextStyle(
                    fontSize: 18,
                    color:
                        colorController.textColor.value.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start recording your favorite hymns',
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        colorController.textColor.value.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await controller.refreshRecordings();
            await controller.refreshPublicRecordings();
          },
          color: colorController.primaryColor.value,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // Personal Recordings Section
              if (personalRecordings.isNotEmpty)
                ExpansionTile(
                  initiallyExpanded: false,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorController.primaryColor.value,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Personal Recordings',
                    style: TextStyle(
                      color: colorController.textColor.value,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${personalRecordings.length} recording${personalRecordings.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: colorController.textColor.value
                          .withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  children: personalRecordings.asMap().entries.map((entry) {
                    final index = entry.key;
                    final recording = entry.value;
return RecordingTileWidget(
                      recording: recording,
                      controller: controller,
                      colorController: colorController,
                      index: index,
                    );
                  }).toList(),
                ),

              // Spacing between sections
              if (personalRecordings.isNotEmpty && publicRecordings.isNotEmpty)
                const SizedBox(height: 16),

              // Public Recordings Section
              if (publicRecordings.isNotEmpty)
                ExpansionTile(
                  initiallyExpanded: false,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.public,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Public Recordings',
                    style: TextStyle(
                      color: colorController.textColor.value,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${publicRecordings.length} recording${publicRecordings.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: colorController.textColor.value
                          .withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  children: publicRecordings.asMap().entries.map((entry) {
                    final index = entry.key;
                    final recording = entry.value;
return RecordingTileWidget(
                      recording: recording,
                      controller: controller,
                      colorController: colorController,
                      index: index + personalRecordings.length,
                      isPublic: true,
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      }),
floatingActionButton: ContextAwareFAB(
        onStartRecording: () {
          // Navigate to standalone recording screen
          Get.to(() => const StandaloneRecordingScreen());
        },
      ),
    );
  }



  void _showDriveDialog(BuildContext context, RecordingController controller,
      ColorController colorController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorController.backgroundColor.value,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.cloud_done,
              color: colorController.primaryColor.value,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Google Drive',
              style: TextStyle(
                color: colorController.textColor.value,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Signed in as:',
              style: TextStyle(
                color: colorController.textColor.value.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              controller.userEmail.value ?? 'Unknown',
              style: TextStyle(
                color: colorController.textColor.value,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: colorController.textColor.value),
            ),
          ),
          Obx(() => controller.isLoading.value
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await controller.syncFromDrive();
                  },
                  icon: const Icon(Icons.sync, size: 18),
                  label: const Text('Sync'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorController.primaryColor.value,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                )),
          ElevatedButton(
            onPressed: () {
              controller.signOutFromDrive();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}


