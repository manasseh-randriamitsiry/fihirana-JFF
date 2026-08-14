import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fihirana/features/recording/domain/entities/user_recording.dart';
import 'package:fihirana/features/recording/presentation/controllers/recording_controller.dart';
import 'package:fihirana/features/auth/presentation/controllers/auth_controller.dart';
import 'recording_tile_dialogs.dart';

class RecordingTileMenu extends StatelessWidget {
  final UserRecording recording;
  final bool isPublic;
  final RecordingController controller = Get.find<RecordingController>();
  final AuthController authController = Get.find<AuthController>();

  RecordingTileMenu({
    super.key,
    required this.recording,
    required this.isPublic,
  });

  bool _canDeleteRecording() {
    // Check if user is admin/super admin
    if (authController.isAdmin || authController.isSuperAdmin) {
      if (kDebugMode) {
        print(
            'RecordingTileMenu: User is admin, can delete recording ${recording.id}');
      }
      return true;
    }

    // Check if user is owner
    final canDelete = RecordingTileDialogs.isOwner(recording);
    if (kDebugMode) {
      print(
          'RecordingTileMenu: Can delete recording ${recording.id}: $canDelete (userId: ${recording.userId}, userEmail: ${recording.userEmail})');
    }
    if (canDelete) {
      if (kDebugMode) {
        print(
            'RecordingTileMenu: Adding delete menu item for recording: ${recording.id}');
      }
    } else {
      if (kDebugMode) {
        print(
            'RecordingTileMenu: NOT adding delete menu item for recording: ${recording.id}');
      }
    }
    return canDelete;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (kDebugMode) {
      print('RecordingTileMenu: Building menu for recording: ${recording.id}');
    }
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: colors.onSurface,
      ),
      color: colors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (kDebugMode) {
          print(
              'RecordingTileMenu: Menu item selected: $value for recording: ${recording.id}');
        }
        switch (value) {
          case 'play':
            controller.showPlayer(
              recording,
              isRecording: false,
              onStopRecording: () {},
            );
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
            if (kDebugMode) {
              print(
                  'RecordingTileMenu: Delete menu item selected for recording: ${recording.id}');
            }
            RecordingTileDialogs.showDeleteConfirmation(context, recording);
            break;
          case 'delete_permanently':
            RecordingTileDialogs.showPermanentDeleteConfirmation(
                context, recording);
            break;
        }
      },
      itemBuilder: (context) {
        if (kDebugMode) {
          print(
              'RecordingTileMenu: Building itemBuilder for recording: ${recording.id}, isPublic: $isPublic');
        }
        final items = <PopupMenuItem<String>>[
          PopupMenuItem(
            value: 'play',
            height: 40,
            child: Row(
              children: [
                Icon(
                  Icons.play_arrow,
                  color: colors.onSurfaceVariant,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  'Lire',
                  style: TextStyle(color: colors.onSurface, fontSize: 13),
                ),
              ],
            ),
          ),
        ];

        if (!isPublic) {
          items.add(PopupMenuItem(
            value: 'rename',
            height: 40,
            child: Row(
              children: [
                Icon(
                  Icons.edit,
                  color: colors.onSurfaceVariant,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  'Renommer',
                  style: TextStyle(color: colors.onSurface, fontSize: 13),
                ),
              ],
            ),
          ));
        }

        items.add(PopupMenuItem(
          value: 'share',
          height: 40,
          child: Row(
            children: [
              Icon(
                Icons.share,
                color: colors.onSurfaceVariant,
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                'Partager',
                style: TextStyle(color: colors.onSurface, fontSize: 13),
              ),
            ],
          ),
        ));

        if (!isPublic && !recording.isPublic) {
          items.add(PopupMenuItem(
            value: 'public',
            height: 40,
            child: Row(
              children: [
                Icon(
                  Icons.public,
                  color: colors.secondary,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  'Rendre public',
                  style: TextStyle(color: colors.onSurface, fontSize: 13),
                ),
              ],
            ),
          ));
        }

        if (isPublic && recording.driveFileId != null) {
          items.add(PopupMenuItem(
            value: 'download',
            height: 40,
            child: Row(
              children: [
                Icon(
                  Icons.download,
                  color: colors.onSurfaceVariant,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  'Télécharger',
                  style: TextStyle(color: colors.onSurface, fontSize: 13),
                ),
              ],
            ),
          ));
        }

        if (!isPublic && recording.driveFileId != null) {
          items.add(PopupMenuItem(
            value: 'reupload',
            height: 40,
            child: Row(
              children: [
                Icon(
                  Icons.cloud_upload,
                  color: colors.primary,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  "Réparer l'envoi",
                  style: TextStyle(color: colors.onSurface, fontSize: 13),
                ),
              ],
            ),
          ));
        }

        if (!isPublic) {
          items.add(PopupMenuItem(
            value: 'export',
            height: 40,
            child: Row(
              children: [
                Icon(
                  Icons.drive_file_move_outlined,
                  color: colors.onSurfaceVariant,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  'Exporter vers...',
                  style: TextStyle(color: colors.onSurface, fontSize: 13),
                ),
              ],
            ),
          ));
        }

        if (!isPublic || _canDeleteRecording()) {
          if (kDebugMode) {
            print('RecordingTileMenu: Adding delete menu item');
          }
          items.add(PopupMenuItem(
            value: 'delete',
            height: 40,
            child: Row(
              children: [
                Icon(
                  Icons.delete_outline,
                  color: colors.error,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  isPublic ? 'Retirer de la liste publique' : 'Supprimer',
                  style: TextStyle(
                    color: colors.error,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ));
        } else {
          if (kDebugMode) {
            print('RecordingTileMenu: NOT adding delete menu item');
          }
        }

        if (RecordingTileDialogs.isAdmin(recording)) {
          items.add(PopupMenuItem(
            value: 'delete_permanently',
            height: 40,
            child: Row(
              children: [
                Icon(
                  Icons.delete_forever,
                  color: colors.error,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  'Supprimer définitivement',
                  style: TextStyle(
                    color: colors.error,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ));
        }

        return items;
      },
    );
  }
}
