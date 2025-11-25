import 'package:fihirana/controller/recording_controller.dart';
import 'package:fihirana/controller/color_controller.dart';
import 'package:fihirana/controller/shell_controller.dart';
import 'package:fihirana/models/user_recording.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class RecordingManagerScreen extends StatelessWidget {
  const RecordingManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Get.put to ensure controller is initialized
    final RecordingController controller =
        Get.put(RecordingController(), permanent: true);
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

        if (controller.recordings.isEmpty) {
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
                    return _RecordingTile(
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
                    return _RecordingTile(
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

class _RecordingTile extends StatelessWidget {
  final UserRecording recording;
  final RecordingController controller;
  final ColorController colorController;
  final int index;
  final bool isPublic;

  const _RecordingTile({
    required this.recording,
    required this.controller,
    required this.colorController,
    required this.index,
    this.isPublic = false,
  });

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: colorController.backgroundColor.value,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorController.primaryColor.value.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPublic
                  ? [
                      Colors.orange,
                      Colors.orange.withValues(alpha: 0.7),
                    ]
                  : [
                      colorController.primaryColor.value,
                      colorController.primaryColor.value.withValues(alpha: 0.7),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              const Center(
                child: Icon(
                  Icons.music_note_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              if (isPublic)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.public,
                      color: Colors.orange,
                      size: 10,
                    ),
                  ),
                ),
            ],
          ),
        ),
        title: Text(
          recording.title,
          style: TextStyle(
            color: colorController.textColor.value,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.music_video,
                  size: 12,
                  color: colorController.iconColor.value.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Hymn ${recording.hymnId} • ${_formatDuration(recording.durationSeconds)}',
                    style: TextStyle(
                      color: colorController.textColor.value
                          .withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: colorController.iconColor.value.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    DateFormat.yMMMd().add_jm().format(recording.createdAt),
                    style: TextStyle(
                      color: colorController.textColor.value
                          .withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Public indicator or Drive status
            if (isPublic)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.public,
                      size: 14,
                      color: Colors.orange,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Public',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else if (recording.driveFileId != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (recording.filePath.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Icon(
                        Icons.check_circle,
                        size: 16,
                        color: colorController.primaryColor.value,
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.cloud_done,
                      size: 18,
                      color: Colors.green,
                    ),
                  ),
                ],
              )
            else
              Obx(() {
                final isUploading =
                    controller.isUploadingRecording(recording.id);
                final uploadError = controller.getUploadError(recording.id);

                if (isUploading) {
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue,
                        ),
                      ),
                    ),
                  );
                } else if (uploadError != null) {
                  return IconButton(
                    icon: const Icon(
                      Icons.cloud_off,
                      color: Colors.red,
                    ),
                    onPressed: () => controller.retryUpload(recording),
                    tooltip:
                        'Upload failed. Tap to retry.\nError: $uploadError',
                  );
                } else {
                  return IconButton(
                    icon: Icon(
                      Icons.cloud_upload_outlined,
                      color: colorController.iconColor.value,
                    ),
                    onPressed: () => controller.uploadToDrive(recording),
                    tooltip: 'Upload to Drive',
                  );
                }
              }),

            // Menu button
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: colorController.iconColor.value,
              ),
              color: colorController.backgroundColor.value,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                switch (value) {
                  case 'share':
                    controller.shareRecordingFile(recording);
                    break;
                  case 'download':
                    controller.downloadRecording(recording);
                    break;
                  case 'export':
                    controller.exportRecording(recording);
                    break;
                  case 'delete':
                    if (!isPublic) {
                      _showDeleteConfirmation(context);
                    }
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(
                        Icons.share,
                        color: colorController.iconColor.value,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Share',
                        style:
                            TextStyle(color: colorController.textColor.value),
                      ),
                    ],
                  ),
                ),
                if (isPublic ||
                    (recording.driveFileId != null &&
                        recording.filePath.isEmpty))
                  PopupMenuItem(
                    value: 'download',
                    child: Row(
                      children: [
                        Icon(
                          Icons.download,
                          color: colorController.iconColor.value,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Download',
                          style:
                              TextStyle(color: colorController.textColor.value),
                        ),
                      ],
                    ),
                  ),
                if (!isPublic)
                  PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(
                          Icons.drive_file_move_outlined,
                          color: colorController.iconColor.value,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Export to...',
                          style:
                              TextStyle(color: colorController.textColor.value),
                        ),
                      ],
                    ),
                  ),
                if (!isPublic)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        onTap: () {
          controller.showPlayer(recording);
        },
      ),
    )
        .animate()
        .slideX(
          duration: 300.ms,
          begin: index % 2 == 0 ? -0.1 : 0.1,
          curve: Curves.easeOut,
        )
        .fadeIn(duration: 300.ms);
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorController.backgroundColor.value,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Delete Recording',
              style: TextStyle(
                color: colorController.textColor.value,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${recording.title}"? This action cannot be undone.',
          style: TextStyle(color: colorController.textColor.value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: colorController.textColor.value),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteRecording(recording);
              Navigator.pop(context);
              Get.snackbar(
                'Deleted',
                'Recording deleted successfully',
                backgroundColor: Colors.red.withValues(alpha: 0.8),
                colorText: Colors.white,
                duration: const Duration(seconds: 2),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
