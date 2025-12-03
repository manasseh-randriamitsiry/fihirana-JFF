import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:fihirana/features/recording/domain/entities/user_recording.dart';
import 'package:fihirana/features/recording/data/services/recording_service.dart';
import 'package:fihirana/features/recording/data/services/google_drive_service.dart';
import 'package:fihirana/features/audio/data/services/local_audio_service.dart';
import 'recording_auth_manager.dart';
import 'recording_state_manager.dart';

/// Manages file operations for recordings
class RecordingFileManager extends GetxController {
  final RecordingService _recordingService;
  final RecordingAuthManager _authManager;
  final RecordingStateManager _stateManager;

  RecordingFileManager({
    required RecordingService recordingService,
    required RecordingAuthManager authManager,
    required RecordingStateManager stateManager,
  })  : _recordingService = recordingService,
        _authManager = authManager,
        _stateManager = stateManager;

  // Upload state tracking
  final RxSet<String> uploadingRecordingIds = <String>{}.obs;
  final RxMap<String, String> uploadErrors = <String, String>{}.obs;

  // Upload management methods
  bool isUploadingRecording(String recordingId) {
    return uploadingRecordingIds.contains(recordingId);
  }

  String? getUploadError(String recordingId) {
    return uploadErrors[recordingId];
  }

  Future<void> retryUpload(UserRecording recording) async {
    uploadErrors.remove(recording.id);
    await uploadToDrive(recording);
  }

  Future<void> uploadToDrive(UserRecording recording) async {
    if (!_authManager.allowToShareAudio.value) {
      Get.snackbar(
        'Access Denied',
        'You are not allowed to upload audio content.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (!_authManager.isDriveSignedIn.value) {
      await _authManager.signInToDrive();
      if (!_authManager.isDriveSignedIn.value) return;
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
        return;
      }
    }

    try {
      _stateManager.isUploading.value = true;
      uploadingRecordingIds.add(recording.id);
      uploadErrors.remove(recording.id);

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
        final webLink = await _authManager.driveService!.getWebViewLink(fileId);
        final updatedRecording = recording.copyWith(
          driveFileId: fileId,
          driveWebLink: webLink,
        );
        await _recordingService.updateRecording(updatedRecording);

        _authManager.fetchStorageQuota();

        Get.snackbar(
          'Success',
          'Recording uploaded to Drive',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      uploadErrors[recording.id] = e.toString();
      Get.snackbar(
        'Error',
        'Failed to upload recording: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _stateManager.isUploading.value = false;
      uploadingRecordingIds.remove(recording.id);
    }
  }

  Future<void> reuploadToDrive(UserRecording recording) async {
    await uploadToDrive(recording);
  }

  // File download/share/export methods
  Future<void> downloadRecording(UserRecording recording) async {
    if (!await _authManager.checkUserCanRecord()) {
      return;
    }

    try {
      if (recording.filePath.isNotEmpty &&
          await File(recording.filePath).exists()) {
        Get.snackbar(
          'Download',
          'Recording is already downloaded.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      if (recording.driveFileId == null) {
        Get.snackbar('Error', 'Cannot download: No Drive file ID found.');
        return;
      }

      Get.snackbar(
        'Downloading',
        'Downloading ${recording.title}...',
        showProgressIndicator: true,
        snackPosition: SnackPosition.BOTTOM,
      );

      String targetPath = recording.filePath;
      if (targetPath.isEmpty) {
        final localService = LocalAudioService();
        await localService.initialize();
        final stats = await localService.getStorageStats();
        final dir = stats['directory'] as String;
        targetPath = path.join(dir, 'recording_${recording.id}.m4a');
      }

      final driveService = _authManager.driveService ?? GoogleDriveService();
      if (!driveService.isSignedIn) {
        await driveService.signInSilently();
      }

      if (!driveService.isSignedIn) {
        throw Exception('Not signed in to Drive');
      }

      final file =
          await driveService.downloadFile(recording.driveFileId!, targetPath);

      if (file != null && await file.exists()) {
        final updatedRecording = recording.copyWith(filePath: file.path);
        await _recordingService.updateRecording(updatedRecording);

        Get.back();
        Get.snackbar(
          'Success',
          'Downloaded ${recording.title}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          colorText: Colors.green,
        );
      } else {
        throw Exception('Download failed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('RecordingFileManager: Download error: $e');
      }
      Get.back();
      Get.snackbar(
        'Error',
        'Failed to download recording: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    }
  }

  Future<void> shareRecordingFile(UserRecording recording) async {
    if (!await _authManager.checkUserCanRecord()) {
      return;
    }

    try {
      String? filePath = recording.filePath;
      bool fileExists = filePath.isNotEmpty && await File(filePath).exists();

      if (!fileExists) {
        if (recording.driveFileId != null) {
          Get.snackbar(
            'Preparing Share',
            'Downloading file to share...',
            showProgressIndicator: true,
            snackPosition: SnackPosition.BOTTOM,
          );

          String targetPath = recording.filePath;
          if (targetPath.isEmpty) {
            final localService = LocalAudioService();
            await localService.initialize();
            final stats = await localService.getStorageStats();
            final dir = stats['directory'] as String;
            targetPath = path.join(dir, 'recording_${recording.id}.m4a');
          }

          final driveService =
              _authManager.driveService ?? GoogleDriveService();
          if (!driveService.isSignedIn) {
            await driveService.signInSilently();
          }

          if (driveService.isSignedIn) {
            final file = await driveService.downloadFile(
                recording.driveFileId!, targetPath);
            if (file != null && await file.exists()) {
              filePath = file.path;

              final updatedRecording = recording.copyWith(filePath: filePath);
              await _recordingService.updateRecording(updatedRecording);
            }
          }
        }
      }

      if (await File(filePath).exists()) {
        await SharePlus.instance.share(
          ShareParams(text: 'Check out my recording of ${recording.title}', files: [XFile(filePath)]),
        );
      } else if (recording.driveWebLink != null) {
        await SharePlus.instance.share(
          ShareParams(text: 'Check out this recording: ${recording.driveWebLink}'),
        );
      } else {
        Get.snackbar('Error', 'Could not share recording. File not found.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('RecordingFileManager: Share error: $e');
      }
      Get.snackbar('Error', 'Failed to share recording');
    }
  }

  Future<void> exportRecording(UserRecording recording) async {
    if (!await _authManager.checkUserCanRecord()) {
      return;
    }

    try {
      String? filePath = recording.filePath;

      if (filePath.isEmpty || !await File(filePath).exists()) {
        if (recording.driveFileId != null) {
          Get.snackbar(
            'Preparing Export',
            'Downloading file...',
            showProgressIndicator: true,
            snackPosition: SnackPosition.BOTTOM,
          );

          String targetPath = recording.filePath;
          if (targetPath.isEmpty) {
            final localService = LocalAudioService();
            await localService.initialize();
            final stats = await localService.getStorageStats();
            final dir = stats['directory'] as String;
            targetPath = path.join(dir, 'recording_${recording.id}.m4a');
          }

          final driveService =
              _authManager.driveService ?? GoogleDriveService();
          if (!driveService.isSignedIn) {
            await driveService.signInSilently();
          }

          if (driveService.isSignedIn) {
            final file = await driveService.downloadFile(
                recording.driveFileId!, targetPath);
            if (file != null && await file.exists()) {
              filePath = file.path;
            }
          }
        }
      }

      if (filePath.isEmpty || !await File(filePath).exists()) {
        Get.snackbar('Error', 'Could not find recording file.');
        return;
      }

      final fileName = path.basename(filePath);
      final sourceFile = File(filePath);
      final bytes = await sourceFile.readAsBytes();

      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Recording',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['m4a'],
        bytes: bytes,
      );

      if (outputPath == null) {
        return;
      }

      Get.snackbar(
        'Success',
        'Exported ${recording.title}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.1),
        colorText: Colors.green,
      );
    } catch (e) {
      if (kDebugMode) {
        print('RecordingFileManager: Export error: $e');
      }
      Get.snackbar(
        'Error',
        'Failed to export recording: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    }
  }
}
