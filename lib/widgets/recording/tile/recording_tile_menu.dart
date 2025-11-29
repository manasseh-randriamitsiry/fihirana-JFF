import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/user_recording.dart';
import '../../../controller/recording_controller.dart';
import '../../../controller/auth_controller.dart';
import '../../../controller/color_controller.dart';
import 'recording_tile_dialogs.dart';

class RecordingTileMenu extends StatelessWidget {
  final UserRecording recording;
  final bool isPublic;
  final RecordingController controller = Get.find<RecordingController>();
  final AuthController authController = Get.find<AuthController>();
  final ColorController colorController = Get.find<ColorController>();

  RecordingTileMenu({
    super.key,
    required this.recording,
    required this.isPublic,
  });

  bool _canDeleteRecording() {
    // Check if user is admin/super admin
    if (authController.isAdmin || authController.isSuperAdmin) return true;

    // Check if user is owner
    return RecordingTileDialogs.isOwner(recording);
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: colorController.textColor.value,
      ),
      color: colorController.backgroundColor.value,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        switch (value) {
          case 'play':
            controller.showPlayer(recording);
            break;
          case 'rename':
            RecordingTileDialogs.showRenameDialog(context, recording);
            break;
          case 'share':
            controller.shareRecordingFile(recording);
            break;
          case 'public':
            RecordingTileDialogs.showMakePublicDialog(context, recording);
            break;
          case 'download':
            controller.downloadRecording(recording);
            break;
          case 'reupload':
            controller.retryUpload(recording);
            break;
          case 'export':
            controller.exportRecording(recording);
            break;
          case 'delete':
            RecordingTileDialogs.showDeleteConfirmation(context, recording);
            break;
          case 'delete_permanently':
            RecordingTileDialogs.showPermanentDeleteConfirmation(
                context, recording);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'play',
          height: 40,
          child: Row(
            children: [
              Icon(
                Icons.play_arrow,
                color: colorController.iconColor.value,
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                'Play',
                style: TextStyle(
                    color: colorController.textColor.value, fontSize: 13),
              ),
            ],
          ),
        ),
        if (!isPublic)
          PopupMenuItem(
            value: 'rename',
            height: 40,
            child: Row(
              children: [
                Icon(
                  Icons.edit,
                  color: colorController.iconColor.value,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  'Rename',
                  style: TextStyle(
                      color: colorController.textColor.value, fontSize: 13),
                ),
              ],
            ),
          ),
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
                    color: colorController.textColor.value, fontSize: 13),
              ),
            ],
          ),
        ),
        if (!isPublic && !recording.isPublic)
          PopupMenuItem(
            value: 'public',
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
                      color: colorController.textColor.value, fontSize: 13),
                ),
              ],
            ),
          ),
        if (isPublic && recording.driveFileId != null)
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
                      color: colorController.textColor.value, fontSize: 13),
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
                      color: colorController.textColor.value, fontSize: 13),
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
                      color: colorController.textColor.value, fontSize: 13),
                ),
              ],
            ),
          ),
        if (!isPublic || _canDeleteRecording())
          PopupMenuItem(
            value: 'delete',
            height: 40,
            child: Row(
              children: [
                const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  isPublic ? 'Remove from Public' : 'Delete',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        // Show permanent delete option for admin owners
        if (RecordingTileDialogs.isAdminAndOwner(recording))
          const PopupMenuItem(
            value: 'delete_permanently',
            height: 40,
            child: Row(
              children: [
                Icon(
                  Icons.delete_forever,
                  color: Colors.red,
                  size: 18,
                ),
                SizedBox(width: 12),
                Text(
                  'Delete Permanently',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
