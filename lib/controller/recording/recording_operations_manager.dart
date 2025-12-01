import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_recording.dart';
import '../../services/interfaces/irecording_service.dart';
import 'recording_auth_manager.dart';
import 'recording_state_manager.dart';
import '../auth_controller.dart';

/// Manages recording CRUD operations
class RecordingOperationsManager extends GetxController {
  final IRecordingService _recordingService;
  final RecordingAuthManager _authManager;
  final RecordingStateManager _stateManager;

  RecordingOperationsManager({
    required IRecordingService recordingService,
    required RecordingAuthManager authManager,
    required RecordingStateManager stateManager,
  }) : _recordingService = recordingService,
       _authManager = authManager,
       _stateManager = stateManager;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    // No specific initialization needed for deleted service as it's handled in RecordingService
  }

  // Recording Actions
  Future<void> startRecording(String hymnId) async {
    if (!await _authManager.checkUserCanRecord()) {
      return;
    }

    // Start recording and capture file path (though we don't need it here)
    await _recordingService.startRecording();
    _stateManager.isRecording.value = true;
    _stateManager.isPaused.value = false;
    _stateManager.resetTimer();
    _stateManager.startTimer();

    if (hymnId != 'unknown' && hymnId != 'standalone') {
      _stateManager.showOverlay(hymnId, 'Hymn $hymnId');
    }
  }

  Future<UserRecording?> stopRecording(String hymnId, String title) async {
    // stopRecording now returns UserRecording? directly from the service
    // But we need to add metadata, so we get the file path from the recorder first
    final recordedData = await _recordingService.stopRecording();
    final duration = _stateManager.recordDuration.value;

    _stateManager.resetRecordingState();

    // The service returns null for now, so we need to handle this differently
    // Get the path from somewhere or create the recording ourselves
    // For now, we'll need to get user info and create the recording
    String? currentUserId;
    String? currentUserEmail;
    String? currentUserPhotoUrl;
    String? currentUserName = _authManager.guestName.value;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      currentUserId = currentUser.uid;
      currentUserEmail = currentUser.email;
      currentUserPhotoUrl = currentUser.photoURL;
      currentUserName = currentUser.displayName ?? currentUserName;
    } else if (_authManager.isDriveSignedIn.value &&
        _authManager.userEmail.value != null) {
      final driveUser = _authManager.currentUser;
      if (driveUser != null) {
        currentUserId = driveUser.id;
        currentUserEmail = driveUser.email;
        currentUserPhotoUrl = driveUser.photoUrl;
        currentUserName = driveUser.displayName ?? currentUserName;
      }
    }

    // If recordedData is provided by service, use it; otherwise we need file path
    if (recordedData != null) {
      // Update with user metadata
      final recording = recordedData.copyWith(
        hymnId: hymnId,
        title: title,
        durationSeconds: duration,
        userId: currentUserId,
        userEmail: currentUserEmail,
        userPhotoUrl: currentUserPhotoUrl,
        userName: currentUserName,
      );

      await _recordingService.saveRecording(recording);
      _stateManager.currentHymnTitle.value = title;
      return recording;
    }

    return null;
  }

  Future<void> pauseRecording() async {
    await _recordingService.pauseRecording();
    _stateManager.isPaused.value = true;
    _stateManager.stopTimer();
  }

  Future<void> resumeRecording() async {
    await _recordingService.resumeRecording();
    _stateManager.isPaused.value = false;
    _stateManager.startTimer();
  }

  // Standalone recording methods for non-hymn recordings
  Future<void> startStandaloneRecording() async {
    if (!await _authManager.checkUserCanRecord()) {
      return;
    }

    await _recordingService.startRecording();
    _stateManager.isRecording.value = true;
    _stateManager.isPaused.value = false;
    _stateManager.resetTimer();
    _stateManager.startTimer();
  }

  Future<UserRecording?> stopStandaloneRecording(String title) async {
    final recordedData = await _recordingService.stopRecording();
    _stateManager.resetRecordingState();

    String? currentUserId;
    String? currentUserEmail;
    String? currentUserPhotoUrl;
    String? currentUserName = _authManager.guestName.value;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      currentUserId = currentUser.uid;
      currentUserEmail = currentUser.email;
      currentUserPhotoUrl = currentUser.photoURL;
      currentUserName = currentUser.displayName ?? currentUserName;
    } else if (_authManager.isDriveSignedIn.value &&
        _authManager.userEmail.value != null) {
      final driveUser = _authManager.currentUser;
      if (driveUser != null) {
        currentUserId = driveUser.id;
        currentUserEmail = driveUser.email;
        currentUserPhotoUrl = driveUser.photoUrl;
        currentUserName = driveUser.displayName ?? currentUserName;
      }
    }

    if (recordedData != null) {
      final recording = recordedData.copyWith(
        hymnId: 'unknown',
        title: title,
        durationSeconds: _stateManager.recordDuration.value,
        userId: currentUserId,
        userEmail: currentUserEmail,
        userPhotoUrl: currentUserPhotoUrl,
        userName: currentUserName,
      );

      await _recordingService.saveRecording(recording);
      return recording;
    }

    return null;
  }

  Future<void> updateRecording(UserRecording recording) async {
    try {
      await _recordingService.updateRecording(recording);
    } catch (e) {
      if (kDebugMode) {
        print('RecordingOperationsManager: Error updating recording: $e');
      }
    }
  }

  // Recording management methods
  Future<void> deleteRecording(UserRecording recording) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final authController = Get.find<AuthController>();

      final isOwner =
          recording.userId == currentUser?.uid ||
          recording.userEmail == currentUser?.email ||
          recording.userEmail == _authManager.userEmail.value;
      final isAdmin = authController.isAdmin || authController.isSuperAdmin;

      if (isOwner) {
        await _deleteRecordingPermanently(recording, currentUser);
      } else if (isAdmin) {
        await _moveRecordingToTrash(recording);
      } else {
        Get.snackbar(
          'Access Denied',
          'You can only delete your own recordings',
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete recording: $e',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  Future<void> deleteRecordingPermanentlyDirect(UserRecording recording) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      await _deleteRecordingPermanently(recording, currentUser);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete recording permanently: $e',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  Future<void> _deleteRecordingPermanently(
    UserRecording recording,
    User? currentUser,
  ) async {
    try {
      await _recordingService.deleteLocalRecordingPermanently(recording.id);

      if (recording.driveFileId != null) {
        try {
          await _authManager.driveService!.deleteFile(recording.driveFileId!);
        } catch (e) {
          if (kDebugMode) {
            print('Failed to delete from Google Drive: $e');
          }
        }
      }

      Get.snackbar(
        'Deleted',
        'Recording permanently deleted',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> moveRecordingToTrash(UserRecording recording) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final authController = Get.find<AuthController>();

      final isOwner =
          recording.userId == currentUser?.uid ||
          recording.userEmail == currentUser?.email ||
          recording.userEmail == _authManager.userEmail.value;
      final isAdmin = authController.isAdmin || authController.isSuperAdmin;

      if (isOwner || isAdmin) {
        await _moveRecordingToTrash(recording);
      } else {
        Get.snackbar(
          'Access Denied',
          'You do not have permission to move this recording to trash',
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to move recording to trash: $e',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  Future<void> _moveRecordingToTrash(UserRecording recording) async {
    try {
      await _recordingService.deleteLocalRecording(recording.id);

      Get.snackbar(
        'Deleted',
        'Recording moved to trash and can be restored',
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> renameRecording(UserRecording recording, String newTitle) async {
    try {
      final updated = recording.copyWith(title: newTitle);
      await _recordingService.updateRecording(updated);
    } catch (e) {
      Get.snackbar('Error', 'Failed to rename recording: $e');
    }
  }

  // Deleted recordings management
  Future<List<UserRecording>> getDeletedRecordings() async {
    return _recordingService.deletedRecordings;
  }

  Future<void> restoreRecording(UserRecording deletedRecording) async {
    try {
      final restoredRecording = UserRecording(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        hymnId: deletedRecording.hymnId,
        title: deletedRecording.title,
        filePath: deletedRecording.filePath,
        durationSeconds: deletedRecording.durationSeconds,
        createdAt: DateTime.now(),
        isPublic: false,
        driveFileId: deletedRecording.driveFileId,
        driveWebLink: deletedRecording.driveWebLink,
        userName: deletedRecording.userName,
        userId: deletedRecording.userId,
        userEmail: deletedRecording.userEmail,
        userPhotoUrl: deletedRecording.userPhotoUrl,
        tags: deletedRecording.tags,
      );

      await _recordingService.saveRecording(restoredRecording);

      await _recordingService.restoreRecording(deletedRecording.id);
      await _recordingService.loadRecordings();

      Get.snackbar(
        'Restored',
        'Recording restored successfully',
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to restore recording: $e',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  Future<void> permanentlyDeleteRecording(
    UserRecording deletedRecording,
  ) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (deletedRecording.driveFileId != null &&
          (deletedRecording.userId == currentUser?.uid ||
              deletedRecording.userEmail == currentUser?.email ||
              deletedRecording.userEmail == _authManager.userEmail.value)) {
        try {
          await _authManager.driveService!.deleteFile(
            deletedRecording.driveFileId!,
          );
        } catch (e) {
          if (kDebugMode) {
            print('Failed to delete from Google Drive: $e');
          }
        }
      }

      await _recordingService.permanentlyDeleteRecording(deletedRecording.id);

      Get.snackbar(
        'Permanently Deleted',
        'Recording has been permanently deleted',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to permanently delete recording: $e',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }
}
