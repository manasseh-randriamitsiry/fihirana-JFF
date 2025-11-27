import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controller/color_controller.dart';
import '../../controller/recording_controller.dart';
import '../../models/user_recording.dart';

class RecordingTileWidget extends StatelessWidget {
  final UserRecording recording;
  final RecordingController controller;
  final ColorController colorController;
  final int index;
  final bool isPublic;

  const RecordingTileWidget({
    super.key,
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
                    recording.hymnId == 'unknown'
                        ? _formatDuration(recording.durationSeconds)
                        : 'Hymn ${recording.hymnId} • ${_formatDuration(recording.durationSeconds)}',
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
                  case 'reupload':
                    if (!isPublic) {
                      controller.reuploadToDrive(recording);
                    }
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
                if (!isPublic && recording.driveFileId != null)
                  PopupMenuItem(
                    value: 'reupload',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cloud_upload,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Fix Upload',
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