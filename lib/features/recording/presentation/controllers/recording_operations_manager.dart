import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fihirana/features/recording/domain/entities/user_recording.dart';
import 'package:fihirana/features/recording/domain/repositories/recording_repository.dart';
import 'recording_auth_manager.dart';
import 'recording_state_manager.dart';
import 'package:fihirana/features/auth/presentation/controllers/auth_controller.dart';

/// Manages recording CRUD operations
class RecordingOperationsManager extends GetxController {
  final RecordingRepository _recordingService;
  final RecordingAuthManager _authManager;
  final RecordingStateManager _stateManager;

  RecordingOperationsManager({
    required RecordingRepository recordingService,
    required RecordingAuthManager authManager,
    required RecordingStateManager stateManager,
  })  : _recordingService = recordingService,
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
    if (kDebugMode) {
      print(
          'RecordingOperationsManager: startRecording called for hymnId: $hymnId');
    }

    if (!await _authManager.checkUserCanRecord()) {
      if (kDebugMode) {
        print('RecordingOperationsManager: User cannot record, returning');
      }
      return;
    }

    try {
      // Start recording and capture file path (though we don't need it here)
      await _recordingService.startRecording();
      _stateManager.isRecording.value = true;
      _stateManager.isPaused.value = false;
      _stateManager.resetTimer();
      _stateManager.startTimer();

      if (hymnId != 'unknown' && hymnId != 'standalone') {
        _stateManager.showOverlay(hymnId, 'Hymn $hymnId');
      }

      if (kDebugMode) {
        print('RecordingOperationsManager: Recording started successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('RecordingOperationsManager: Error starting recording: $e');
      }
      _stateManager.isRecording.value = false;
    }
  }

  Future<UserRecording?> stopRecording(String hymnId, String title) async {
    if (kDebugMode) {
      print(
          'RecordingOperationsManager: stopRecording called for hymnId: $hymnId, title: $title');
    }

    // stopRecording now returns UserRecording? directly from the service
    // But we need to add metadata, so we get -> file path from recorder first
    final recordedData = await _recordingService.stopRecording();
    final duration = _stateManager.recordDuration.value;

    _stateManager.resetRecordingState();

    if (kDebugMode) {
      print(
          'RecordingOperationsManager: recordedData from service: $recordedData');
    }

    // Get user info for metadata
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
      if (kDebugMode) {
        print('RecordingOperationsManager: Creating recording with metadata');
      }

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

      try {
        await _recordingService.saveRecording(recording);
        _stateManager.currentHymnTitle.value = title;
        if (kDebugMode) {
          print('RecordingOperationsManager: Recording saved successfully');
        }
        return recording;
      } catch (e) {
        if (kDebugMode) {
          print('RecordingOperationsManager: Error saving recording: $e');
        }
        return null;
      }
    } else {
      if (kDebugMode) {
        print(
            'RecordingOperationsManager: No recorded data returned from service');
      }
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

  Future<void> moveRecordingToTrash(UserRecording recording) async {
    try {
      await _recordingService.deleteRecording(recording.id);
      Get.snackbar(
        'Moved to Trash',
        'Recording has been moved to trash',
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to move recording to trash: $e',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  Future<void> renameRecording(UserRecording recording, String newTitle) async {
    try {
      final updatedRecording = recording.copyWith(title: newTitle);
      await _recordingService.updateRecording(updatedRecording);
      Get.snackbar(
        'Renamed',
        'Recording has been renamed',
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'errorTitle'.tr,
        'errorRestoringRecording'.trParams({'error': e.toString()}),
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  Future<List<UserRecording>> getDeletedRecordings() async {
    return _recordingService.deletedRecordings;
  }

  Future<void> restoreRecording(UserRecording deletedRecording) async {
    try {
      await _recordingService.restoreRecording(deletedRecording.id);
      Get.snackbar(
        'Restored',
        'Recording has been restored from trash',
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
      UserRecording deletedRecording) async {
    try {
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

  // Recording management methods
  Future<void> deleteRecording(UserRecording recording) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final authController = Get.find<AuthController>();

      final isOwner = recording.userId == currentUser?.uid ||
          recording.userEmail == currentUser?.email ||
          recording.userEmail == _authManager.userEmail.value;
      final isAdmin = authController.isAdmin || authController.isSuperAdmin;

      if (isOwner) {
        await deleteRecordingPermanentlyDirect(recording);
      } else if (isAdmin) {
        await moveRecordingToTrash(recording);
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
    if (kDebugMode) {
      print(
          'RecordingOperationsManager: deleteRecordingPermanentlyDirect called for recording: ${recording.id}');
    }
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      await deleteRecordingPermanently(recording, currentUser);
      if (kDebugMode) {
        print(
            'RecordingOperationsManager: deleteRecordingPermanentlyDirect completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            'RecordingOperationsManager: Error in deleteRecordingPermanentlyDirect: $e');
      }
      Get.snackbar(
        'Error',
        'Failed to delete recording permanently: $e',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  Future<void> deleteRecordingPermanently(
    UserRecording recording,
    User? currentUser,
  ) async {
    if (kDebugMode) {
      print(
          'RecordingOperationsManager: deleteRecordingPermanently called for recording: ${recording.id}');
    }
    try {
      // For public recordings, unpublish first to clean up Firestore
      if (recording.isPublic) {
        if (kDebugMode) {
          print(
              'RecordingOperationsManager: Recording is public, unpublishing from Firestore');
        }
        await _recordingService.unpublishRecording(recording.id);
        if (kDebugMode) {
          print(
              'RecordingOperationsManager: Public recording unpublished from Firestore');
        }
      }

      await _recordingService.deleteLocalRecordingPermanently(recording.id);
      if (kDebugMode) {
        print('RecordingOperationsManager: local delete completed');
      }

      if (recording.driveFileId != null) {
        if (kDebugMode) {
          print(
              'RecordingOperationsManager: Recording has driveFileId: ${recording.driveFileId}, attempting Drive deletion');
        }
        try {
          if (_authManager.driveService != null) {
            // Check if Drive authentication is valid before attempting deletion
            final isAuthValid =
                await _authManager.driveService!.isDriveAuthenticationValid();
            if (!isAuthValid) {
              if (kDebugMode) {
                print(
                    'RecordingOperationsManager: Drive authentication is invalid, attempting to re-authenticate');
              }
              final signInResult = await _authManager.driveService!.signIn();
              if (signInResult == null) {
                if (kDebugMode) {
                  print(
                      'RecordingOperationsManager: Re-authentication failed, cannot delete from Drive');
                }
                Get.snackbar(
                  'Authentication Required',
                  'Please sign in to Google Drive to delete files',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 3),
                );
              } else {
                if (kDebugMode) {
                  print(
                      'RecordingOperationsManager: Re-authentication successful, proceeding with deletion');
                }
              }
            }

            // Check if file can be deleted before attempting
            final canDelete = await _authManager.driveService!
                .canDeleteFile(recording.driveFileId!);
            if (!canDelete) {
              if (kDebugMode) {
                print(
                    'RecordingOperationsManager: Cannot delete file - insufficient permissions');
              }
              Get.snackbar(
                'Cannot Delete',
                'This file cannot be deleted from Google Drive. You may not have sufficient permissions.',
                backgroundColor: Colors.orange,
                colorText: Colors.white,
                duration: const Duration(seconds: 4),
              );
            } else {
              final deleteSuccess = await _authManager.driveService!
                  .deleteFile(recording.driveFileId!);
              if (deleteSuccess) {
                if (kDebugMode) {
                  print(
                      'RecordingOperationsManager: Drive deletion successful');
                }
              } else {
                if (kDebugMode) {
                  print(
                      'RecordingOperationsManager: Drive file deletion failed');
                }
                Get.snackbar(
                  'Deletion Failed',
                  'Failed to delete file from Google Drive. The file will be removed from the app only.',
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 4),
                );
              }
            }
          } else {
            if (kDebugMode) {
              print('RecordingOperationsManager: Drive service not available');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('RecordingOperationsManager: Error deleting from Drive: $e');
          }
          // Continue anyway - local deletion is more important
        }
      } else {
        if (kDebugMode) {
          print(
              'RecordingOperationsManager: Recording has no driveFileId, skipping Drive deletion');
        }
      }

      // Refresh the recording list to update UI
      try {
        await _recordingService.loadRecordings();
        if (kDebugMode) {
          print(
              'RecordingOperationsManager: Recording list refreshed after deletion');
        }

        // Also refresh public recordings if this was a public recording
        if (recording.isPublic) {
          await _recordingService.loadPublicRecordings();
          if (kDebugMode) {
            print(
                'RecordingOperationsManager: Public recordings list refreshed after deletion');
          }
        }
      } catch (refreshError) {
        if (kDebugMode) {
          print(
              'RecordingOperationsManager: Error refreshing recording list: $refreshError');
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
      if (kDebugMode) {
        print(
            'RecordingOperationsManager: Error in deleteRecordingPermanently: $e');
      }
      rethrow;
    }
  }

  Future<void> moveRecordingToTrashWithPermission(
      UserRecording recording) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final authController = Get.find<AuthController>();

      final isOwner = recording.userId == currentUser?.uid ||
          recording.userEmail == currentUser?.email ||
          recording.userEmail == _authManager.userEmail.value;
      final isAdmin = authController.isAdmin || authController.isSuperAdmin;

      if (isOwner || isAdmin) {
        await moveRecordingToTrash(recording);
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

  Future<void> restoreRecordingWithNewId(UserRecording deletedRecording) async {
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

  Future<void> permanentlyDeleteRecordingWithDrive(
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
