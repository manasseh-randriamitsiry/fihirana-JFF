import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controller/color_controller.dart';
import '../../controller/recording_controller.dart';
import '../../controller/auth_controller.dart';
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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colorController.backgroundColor.value,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorController.primaryColor.value.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        dense: true,
        leading: Container(
          width: 40,
          height: 40,
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
            borderRadius:
                BorderRadius.circular(20), // Circular for user avatar feel
          ),
          child: Stack(
            children: [
              Center(
                child: recording.userPhotoUrl != null &&
                        recording.userPhotoUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          recording.userPhotoUrl!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.music_note_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
              if (isPublic)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.orange, width: 1),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.public,
                        color: Colors.orange,
                        size: 8,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                recording.title,
                style: TextStyle(
                  color: colorController.textColor.value,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (recording.userName != null &&
                recording.userName!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      colorController.primaryColor.value.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  recording.userName!,
                  style: TextStyle(
                    color: colorController.primaryColor.value,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        subtitle: Row(
          children: [
            Icon(
              Icons.access_time,
              size: 10,
              color: colorController.textColor.value.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 4),
            Text(
              _formatDuration(recording.durationSeconds),
              style: TextStyle(
                color: colorController.textColor.value.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '•',
              style: TextStyle(
                color: colorController.textColor.value.withValues(alpha: 0.3),
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                DateFormat.yMMMd().format(recording.createdAt),
                style: TextStyle(
                  color: colorController.textColor.value.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (recording.driveFileId != null && !isPublic)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.cloud_done,
                  size: 16,
                  color: Colors.green.withValues(alpha: 0.7),
                ),
              ),
            if (!isPublic && recording.driveFileId == null)
              Obx(() {
                final isUploading =
                    controller.isUploadingRecording(recording.id);
                final uploadError = controller.getUploadError(recording.id);

                if (isUploading) {
                  return const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  );
                } else if (uploadError != null) {
                  return GestureDetector(
                    onTap: () => controller.retryUpload(recording),
                    child: const Icon(
                      Icons.cloud_off,
                      color: Colors.red,
                      size: 18,
                    ),
                  );
                } else {
                  return IconButton(
                    icon: Icon(
                      Icons.cloud_upload_outlined,
                      color: colorController.iconColor.value
                          .withValues(alpha: 0.5),
                      size: 20,
                    ),
                    onPressed: () => controller.uploadToDrive(recording),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Upload to Drive',
                  );
                }
              }),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: colorController.iconColor.value.withValues(alpha: 0.7),
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
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
                  case 'make_public':
                    if (!isPublic) {
                      _showMakePublicDialog(context, recording);
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
                  height: 40,
                  child: Row(
                    children: [
                      Icon(
                        Icons.share,
                        color: colorController.iconColor.value,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Share',
                        style: TextStyle(
                            color: colorController.textColor.value,
                            fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (!isPublic)
                  PopupMenuItem(
                    value: 'make_public',
                    height: 40,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.public,
                          color: Colors.blue,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Make Public',
                          style: TextStyle(
                              color: colorController.textColor.value,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                if (isPublic ||
                    (recording.driveFileId != null &&
                        recording.filePath.isEmpty))
                  PopupMenuItem(
                    value: 'download',
                    height: 40,
                    child: Row(
                      children: [
                        Icon(
                          Icons.download,
                          color: colorController.iconColor.value,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Download',
                          style: TextStyle(
                              color: colorController.textColor.value,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                if (!isPublic && recording.driveFileId != null)
                  PopupMenuItem(
                    value: 'reupload',
                    height: 40,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cloud_upload,
                          color: Colors.orange,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Fix Upload',
                          style: TextStyle(
                              color: colorController.textColor.value,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                if (!isPublic)
                  PopupMenuItem(
                    value: 'export',
                    height: 40,
                    child: Row(
                      children: [
                        Icon(
                          Icons.drive_file_move_outlined,
                          color: colorController.iconColor.value,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Export to...',
                          style: TextStyle(
                              color: colorController.textColor.value,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                if (!isPublic)
                  const PopupMenuItem(
                    value: 'delete',
                    height: 40,
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 18,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 13,
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

  void _showMakePublicDialog(BuildContext context, UserRecording recording) {
    final titleController = TextEditingController(text: recording.title);
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: colorController.backgroundColor.value,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(
                Icons.public,
                color: Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Make Recording Public',
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
                'This will upload the recording to Google Drive (if not already uploaded) and make it visible to everyone using the app.',
                style: TextStyle(
                    color:
                        colorController.textColor.value.withValues(alpha: 0.7),
                    fontSize: 12),
              ),
              const SizedBox(height: 16),
              Text(
                'Recording Title:',
                style: TextStyle(
                  color: colorController.textColor.value,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: titleController,
                style: TextStyle(color: colorController.textColor.value),
                decoration: InputDecoration(
                  hintText: 'Enter recording title',
                  hintStyle: TextStyle(
                      color: colorController.textColor.value
                          .withValues(alpha: 0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: colorController.textColor.value
                            .withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  errorText: errorMessage,
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                ),
                onChanged: (_) {
                  // Clear error when user types
                  if (errorMessage != null) {
                    setState(() {
                      errorMessage = null;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(color: colorController.textColor.value),
              ),
            ),
            Obx(() => controller.isUploading.value
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : ElevatedButton(
                    onPressed: () async {
                      final title = titleController.text.trim();
                      if (title.isEmpty) {
                        setState(() {
                          errorMessage = 'Title cannot be empty';
                        });
                        return;
                      }

                      // Attempt to make recording public
                      final result = await controller.makeRecordingPublic(
                        recording,
                        customTitle: title != recording.title ? title : null,
                      );

                      // Only close dialog if successful
                      if (result == PublishRecordingResult.success && dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      } else if (result == PublishRecordingResult.duplicateTitle) {
                        // Show error in the text field
                        setState(() {
                          errorMessage =
                              'This title already exists for this hymn';
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Make Public'),
                  )),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final authController = Get.find<AuthController>();
    final isAdmin = authController.isAdmin;
    
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
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${recording.title}"?',
              style:
                  TextStyle(color: colorController.textColor.value, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Text(
                isAdmin 
                    ? 'This recording will be moved to trash and can be restored from the admin panel.'
                    : 'This recording will be moved to trash and can be restored.',
                style: TextStyle(
                  color: Colors.orange.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ),
          ],
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
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Move to Trash'),
          ),
        ],
      ),
    );
  }
}
