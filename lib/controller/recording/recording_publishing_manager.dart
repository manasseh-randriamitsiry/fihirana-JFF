import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_recording.dart';
import '../../services/audio/recording_service.dart';
import 'recording_auth_manager.dart';
import 'recording_state_manager.dart';
import '../../l10n/app_localizations.dart';

enum PublishRecordingResult {
  success,
  duplicateTitle,
  accessDenied,
  signInRequired,
  storageFull,
  uploadFailed,
  publishFailed,
  unknownError,
}

/// Manages public recording features
class RecordingPublishingManager extends GetxController {
  final RecordingService _recordingService;
  final RecordingAuthManager _authManager;
  final RecordingStateManager _stateManager;

  RecordingPublishingManager({
    required RecordingService recordingService,
    required RecordingAuthManager authManager,
    required RecordingStateManager stateManager,
  })  : _recordingService = recordingService,
        _authManager = authManager,
        _stateManager = stateManager;

  final RxList<UserRecording> publicRecordings = <UserRecording>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Load public recordings when manager is initialized
    refreshPublicRecordings();
  }

  Future<List<UserRecording>> loadPublicRecordings({String? hymnId}) async {
    try {
      return await _recordingService.getPublicRecordings(hymnId: hymnId);
    } catch (e) {
      if (kDebugMode) {
        print('RecordingPublishingManager: Load public recordings error: $e');
      }
      return [];
    }
  }

  Future<void> refreshPublicRecordings({String? hymnId}) async {
    try {
      final recordings =
          await _recordingService.getPublicRecordings(hymnId: hymnId);
      publicRecordings.value = recordings;
      if (kDebugMode) {
        print(
            'RecordingPublishingManager: Loaded ${recordings.length} public recordings');
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            'RecordingPublishingManager: Refresh public recordings error: $e');
      }
    }
  }

  // Publishing methods
  Future<PublishRecordingResult> makeRecordingPublic(UserRecording recording,
      {String? customTitle}) async {
    if (!_authManager.allowToShareAudio.value) {
      Get.snackbar(
        'Access Denied',
        'You are not allowed to share audio content.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return PublishRecordingResult.accessDenied;
    }

    if (!_authManager.isDriveSignedIn.value) {
      await _authManager.signInToDrive();
      if (!_authManager.isDriveSignedIn.value) {
        Get.snackbar(
          'Sign In Required',
          'You must be signed in to Google Drive to share recordings.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return PublishRecordingResult.signInRequired;
      }
    }

    await _authManager.fetchStorageQuota();
    final quota = _authManager.storageQuota.value;
    if (quota != null && quota.limit != null && quota.usage != null) {
      final limit = int.tryParse(quota.limit!) ?? 0;
      final usage = int.tryParse(quota.usage!) ?? 0;
      final fileSize = File(recording.filePath).lengthSync();

      if (usage + fileSize > limit) {
        Get.snackbar(
          'Storage Full',
          'Your Google Drive storage is full. Cannot upload recording.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        return PublishRecordingResult.storageFull;
      }
    }

    try {
      _stateManager.isUploading.value = true;
      UserRecording recordingToPublish = recording;

      // Get user info for the recording
      final currentUser = _authManager.currentUser;
      final photoUrl = currentUser?.photoUrl;
      final prefs = await SharedPreferences.getInstance();
      final userName =
          prefs.getString('guest_name') ?? _authManager.guestName.value;

      if (customTitle != null && customTitle.isNotEmpty) {
        recordingToPublish = recording.copyWith(title: customTitle);
      }

      // Add user info if not already present
      if (recordingToPublish.userPhotoUrl == null ||
          recordingToPublish.userName == null) {
        recordingToPublish = recordingToPublish.copyWith(
          userName: userName.isNotEmpty ? userName : currentUser?.displayName,
          userPhotoUrl: photoUrl,
        );
      }

      if (recording.driveFileId == null) {
        Get.snackbar(
          'Uploading',
          'Uploading recording to Drive first...',
          backgroundColor: Colors.blue,
          colorText: Colors.white,
        );

        final file = File(recording.filePath);
        if (!await file.exists()) {
          throw Exception('Recording file not found');
        }

        final fileId = await _authManager.driveService!.uploadFile(
          file,
          '${recording.title}.m4a',
          description: 'Hymn: ${recording.hymnId}',
        );

        if (fileId != null) {
          final publicLink =
              await _authManager.driveService!.getPublicLink(fileId);
          final webLink =
              await _authManager.driveService!.getWebViewLink(fileId);

          recordingToPublish = recording.copyWith(
            driveFileId: fileId,
            driveWebLink: webLink,
            publicLink: publicLink,
          );
          await _recordingService.updateRecording(recordingToPublish);
          _authManager.fetchStorageQuota();
        } else {
          return PublishRecordingResult.uploadFailed;
        }
      }

      final titleExists = await _recordingService.titleExistsForHymn(
        recordingToPublish.hymnId,
        recordingToPublish.title,
      );
      if (titleExists) {
        return PublishRecordingResult.duplicateTitle;
      }

      final success =
          await _recordingService.publishRecording(recordingToPublish);

      if (success) {
        final updated = recordingToPublish.copyWith(isPublic: true);
        await _recordingService.updateRecording(updated);
        await _recordingService.loadRecordings();
        await refreshPublicRecordings();

        Get.snackbar(
          'Success',
          'Recording is now public!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return PublishRecordingResult.success;
      } else {
        return PublishRecordingResult.publishFailed;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to make recording public: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      return PublishRecordingResult.unknownError;
    } finally {
      _stateManager.isUploading.value = false;
    }
  }

  Future<void> publishRecording(UserRecording recording) async {
    if (!await _authManager.checkUserCanRecord()) {
      return;
    }

    try {
      Get.snackbar(
        'Publishing',
        'Making recording public...',
        showProgressIndicator: true,
        snackPosition: SnackPosition.BOTTOM,
      );

      final prefs = await SharedPreferences.getInstance();
      final userName =
          prefs.getString('guest_name') ?? _authManager.guestName.value;

      // Get user photo URL from Drive account
      final currentUser = _authManager.currentUser;
      final photoUrl = currentUser?.photoUrl;

      String? driveFileId = recording.driveFileId;
      String? publicLink;

      if (driveFileId == null && recording.filePath.isNotEmpty) {
        final file = File(recording.filePath);
        if (await file.exists()) {
          driveFileId = await _authManager.driveService!.uploadFile(
            file,
            recording.title,
            isPublic: true,
          );
        }
      } else if (driveFileId != null) {
        await _authManager.driveService!.setFilePublic(driveFileId);
      }

      if (driveFileId != null) {
        publicLink =
            await _authManager.driveService!.getPublicLink(driveFileId);
      }

      if (driveFileId == null || publicLink == null) {
        throw Exception('Failed to upload or get public link');
      }

      var updatedRecording = recording.copyWith(
        isPublic: true,
        driveFileId: driveFileId,
        publicLink: publicLink,
        userName: userName,
        userPhotoUrl: photoUrl,
      );

      UserRecording currentRecording = updatedRecording;
      bool titleExists = await _recordingService.titleExistsForHymn(
        currentRecording.hymnId,
        currentRecording.title,
      );

      while (titleExists) {
        Get.back();
        final newTitle = await _showDuplicateTitleDialog(currentRecording);
        if (newTitle == null) {
          return;
        }
        currentRecording = currentRecording.copyWith(title: newTitle);
        titleExists = await _recordingService.titleExistsForHymn(
          currentRecording.hymnId,
          currentRecording.title,
        );
      }

      final success =
          await _recordingService.publishRecording(currentRecording);
      if (success) {
        final finalRecording = currentRecording.copyWith(isPublic: true);
        await _recordingService.updateRecording(finalRecording);
        await _recordingService.loadRecordings();
        await refreshPublicRecordings();

        Get.back();
        Get.snackbar(
          'Success',
          'Recording is now public!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        throw Exception('Failed to publish to public database');
      }
    } catch (e) {
      Get.back();
      Get.snackbar(
        'Error',
        'Failed to publish recording: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<String?> _showDuplicateTitleDialog(UserRecording recording) async {
    final TextEditingController controller =
        TextEditingController(text: recording.title);
    String? result;
    final l10n = AppLocalizations.of(Get.context!)!;

    try {
      await Get.dialog(
        AlertDialog(
          title: Text(l10n.duplicateTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.chooseHowToDelete(recording.title)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: l10n.enterNewName,
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                result = controller.text.trim();
                Get.back();
              },
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }

    return result?.isEmpty == true ? null : result;
  }

  Future<void> unpublishRecording(UserRecording recording) async {
    try {
      await _recordingService.unpublishRecording(recording.id);
      final updated = recording.copyWith(isPublic: false);
      await _recordingService.updateRecording(updated);
      await _recordingService.loadRecordings();
      await refreshPublicRecordings();
    } catch (e) {
      if (kDebugMode) {
        print('RecordingPublishingManager: Failed to unpublish recording: $e');
      }
    }
  }
}
