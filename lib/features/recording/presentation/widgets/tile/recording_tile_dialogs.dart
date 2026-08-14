import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fihirana/features/recording/domain/entities/user_recording.dart';
import 'package:fihirana/features/recording/presentation/controllers/recording_controller.dart';
import 'package:fihirana/features/auth/presentation/controllers/auth_controller.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';

class RecordingTileDialogs {
  static final ColorController colorController = Get.find<ColorController>();
  static RecordingController get controller {
    final ctrl = Get.find<RecordingController>();
    if (kDebugMode) {
      print('RecordingTileDialogs: Got controller instance: ${ctrl.hashCode}');
    }
    return ctrl;
  }

  static final AuthController authController = Get.find<AuthController>();

  static bool isAdminAndOwner(UserRecording recording) {
    final currentUser = FirebaseAuth.instance.currentUser;

    // Check if user is admin/super admin
    final isAdmin = authController.isAdmin || authController.isSuperAdmin;

    // Check ownership using both Firebase User UID/Email AND Controller Email
    // This handles cases where Firebase Auth might be out of sync or user is signed in via Drive
    final isOwner = (currentUser != null &&
            (recording.userId == currentUser.uid ||
                recording.userEmail == currentUser.email)) ||
        (controller.userEmail.value != null &&
            recording.userEmail == controller.userEmail.value);

    return isAdmin && isOwner;
  }

  static bool isAdmin(UserRecording recording) {
    // Check if user is admin/super admin (regardless of ownership)
    return authController.isAdmin || authController.isSuperAdmin;
  }

  static bool isOwner(UserRecording recording) {
    final currentUser = FirebaseAuth.instance.currentUser;
    return (currentUser != null &&
            (recording.userId == currentUser.uid ||
                recording.userEmail == currentUser.email)) ||
        (controller.userEmail.value != null &&
            recording.userEmail == controller.userEmail.value);
  }

  static void showDeleteConfirmation(
      BuildContext context, UserRecording recording) {
    if (kDebugMode) {
      print(
          'RecordingTileDialogs: showDeleteConfirmation called for recording: ${recording.id} - ${recording.title}');
    }
    final l10n = AppLocalizations.of(context);
    final bool owner = isOwner(recording);
    final bool adminAndOwner = isAdminAndOwner(recording);
    if (kDebugMode) {
      print('RecordingTileDialogs: owner=$owner, adminAndOwner=$adminAndOwner');
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorController.backgroundColor.value,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.delete_outline,
              color: owner ? Colors.red : Colors.orange,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              adminAndOwner
                  ? l10n.deleteRecording
                  : (owner ? l10n.deletePermanently : l10n.moveToTrash),
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
              adminAndOwner
                  ? l10n.chooseHowToDelete(recording.title)
                  : l10n.sureToDelete(recording.title),
              style: TextStyle(
                  color: colorController.textColor.value, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: owner
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: owner
                      ? Colors.red.withValues(alpha: 0.3)
                      : Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                adminAndOwner
                    ? l10n.chooseHowToDelete(recording.title)
                    : (owner
                        ? l10n.historyCannotBeUndone
                        : l10n.deleteRecordingQuestion),
                style: TextStyle(
                  color: owner
                      ? Colors.red.withValues(alpha: 0.8)
                      : Colors.orange.withValues(alpha: 0.8),
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
              'Annuler',
              style: TextStyle(color: colorController.textColor.value),
            ),
          ),
          if (adminAndOwner) ...[
            ElevatedButton(
              onPressed: () {
                controller.moveRecordingToTrash(recording);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(l10n.moveToTrash),
            ),
            ElevatedButton(
              onPressed: () {
                controller.deleteRecordingPermanentlyDirect(recording);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(l10n.deletePermanently),
            ),
          ] else
            ElevatedButton(
              onPressed: () {
                if (kDebugMode) {
                  print(
                      'RecordingTileDialogs: Delete button pressed for recording: ${recording.id}');
                }
                controller.deleteRecording(recording);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: owner ? Colors.red : Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(owner ? l10n.deletePermanently : l10n.moveToTrash),
            ),
        ],
      ),
    );
  }

  static void showPermanentDeleteConfirmation(
      BuildContext context, UserRecording recording) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorController.backgroundColor.value,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Supprimer définitivement',
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
              'Voulez-vous vraiment supprimer définitivement "${recording.title}" ?',
              style: TextStyle(
                  color: colorController.textColor.value, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3))),
              child: Text(
                "Cet enregistrement sera définitivement supprimé de Google Drive, Firebase et du stockage local. Cette action est irréversible.",
                style: TextStyle(
                  color: Colors.red.withValues(alpha: 0.8),
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
              'Annuler',
              style: TextStyle(color: colorController.textColor.value),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteRecordingPermanentlyDirect(recording);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(l10n.deletePermanently),
          ),
        ],
      ),
    );
  }

  static void showMakePublicDialog(
      BuildContext context, UserRecording recording) {
    final l10n = AppLocalizations.of(context);
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
                "Rendre l'enregistrement public",
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
                "L'enregistrement sera envoyé vers Google Drive, s'il ne l'est pas déjà, puis rendu visible par tous les utilisateurs de l'application.",
                style: TextStyle(
                    color:
                        colorController.textColor.value.withValues(alpha: 0.7),
                    fontSize: 12),
              ),
              const SizedBox(height: 16),
              Text(
                "Titre de l'enregistrement :",
                style: TextStyle(
                  color: colorController.textColor.value,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: titleController,
                style: TextStyle(color: colorController.textColor.value),
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [],
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.text,
                smartDashesType: SmartDashesType.disabled,
                smartQuotesType: SmartQuotesType.disabled,
                decoration: InputDecoration(
                  hintText: "Saisissez le titre de l'enregistrement",
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
                    borderSide:
                        const BorderSide(color: Colors.orange, width: 2),
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
                l10n.cancel,
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
                      if (result == PublishRecordingResult.success &&
                          dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      } else if (result ==
                          PublishRecordingResult.duplicateTitle) {
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
                    child: Text(l10n.makePublic),
                  )),
          ],
        ),
      ),
    ).then((_) {
      titleController.dispose();
    });
  }

  static void showRenameDialog(BuildContext context, UserRecording recording) {
    final l10n = AppLocalizations.of(context);
    final titleController = TextEditingController(text: recording.title);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorController.backgroundColor.value,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.renameRecording,
          style: TextStyle(
            color: colorController.textColor.value,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: titleController,
          style: TextStyle(color: colorController.textColor.value),
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: const [],
          textInputAction: TextInputAction.done,
          keyboardType: TextInputType.text,
          smartDashesType: SmartDashesType.disabled,
          smartQuotesType: SmartQuotesType.disabled,
          decoration: InputDecoration(
            hintText: l10n.enterNewName,
            hintStyle: TextStyle(
                color: colorController.textColor.value.withValues(alpha: 0.5)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                  color:
                      colorController.textColor.value.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.orange, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(color: colorController.textColor.value),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = titleController.text.trim();
              if (newName.isNotEmpty && newName != recording.title) {
                controller.renameRecording(recording, newName);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(l10n.rename),
          ),
        ],
      ),
    ).then((_) {
      titleController.dispose();
    });
  }
}
