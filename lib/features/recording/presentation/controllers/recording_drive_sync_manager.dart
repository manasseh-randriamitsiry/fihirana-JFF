import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:fihirana/features/recording/domain/entities/user_recording.dart';
import 'package:fihirana/features/recording/data/services/recording_service.dart';

import 'package:fihirana/features/audio/data/services/audio_service.dart';
import 'recording_auth_manager.dart';
import 'recording_state_manager.dart';

/// Manages Google Drive synchronization and periodic refresh
class RecordingDriveSyncManager extends GetxController {
  final RecordingService _recordingService;
  final RecordingAuthManager _authManager;
  final RecordingStateManager _stateManager;
  final _uuid = const Uuid();

  // Timer for periodic refresh
  Timer? _periodicRefreshTimer;

  RecordingDriveSyncManager({
    required RecordingService recordingService,
    required RecordingAuthManager authManager,
    required RecordingStateManager stateManager,
  })  : _recordingService = recordingService,
        _authManager = authManager,
        _stateManager = stateManager;

  // Public getter for auth manager
  RecordingAuthManager get authManager => _authManager;

  // Public getter for drive sign-in status
  RxBool get isDriveSignedIn => _authManager.isDriveSignedIn;

  // Data
  final RxList<UserRecording> recordings = <UserRecording>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  @override
  void onClose() {
    _periodicRefreshTimer?.cancel();
    super.onClose();
  }

  Future<void> _initialize() async {
    try {
      // Bind recording stream
      await _recordingService.initialize();
      recordings.bindStream(_recordingService.recordings.stream);

      // Listen to stream for debugging
      recordings.listen((recordingsList) {
        if (kDebugMode) {
          print(
              'RecordingDriveSyncManager: Stream updated with ${recordingsList.length} recordings');
        }
      });

      // Start periodic refresh
      _startPeriodicRefresh();
    } catch (e) {
      if (kDebugMode) {
        print('RecordingDriveSyncManager: Initialization error: $e');
      }
      _stateManager.lastError.value = 'Sync manager initialization failed: $e';
    }
  }

  /// Start periodic refresh of recordings
  void _startPeriodicRefresh() {
    _periodicRefreshTimer =
        Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (kDebugMode) {
        print('RecordingDriveSyncManager: Periodic refresh triggered');
      }

      if (!_stateManager.isLoading.value) {
        _recordingService.loadRecordings();
      }

      if (!_authManager.isDriveSignedIn.value && timer.tick % 4 == 0) {
        _authManager.checkForSilentSignIn();
      }

      if (_authManager.isDriveSignedIn.value &&
          timer.tick % 10 == 0 &&
          !_stateManager.isLoading.value) {
        syncFromDrive();
      }

      // Validate and cleanup orphaned public recordings every 5 minutes (every 10 ticks of 30-second timer)
      if (timer.tick % 10 == 0 && !_stateManager.isLoading.value) {
        if (kDebugMode) {
          print(
              'RecordingDriveSyncManager: Checking for orphaned recordings cleanup (tick: ${timer.tick})');
        }

        try {
          final cleanedUpCount = await _recordingService
              .validateAndCleanupOrphanedPublicRecordings();
          if (kDebugMode) {
            if (cleanedUpCount > 0) {
              print(
                  'RecordingDriveSyncManager: Cleaned up $cleanedUpCount orphaned public recordings');
            } else {
              print(
                  'RecordingDriveSyncManager: No orphaned recordings found to clean up');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print(
                'RecordingDriveSyncManager: Error during orphaned recording cleanup: $e');
          }
        }
      }
    });
  }

  /// Manual cleanup of orphaned public recordings
  Future<int> cleanupOrphanedPublicRecordings() async {
    try {
      if (kDebugMode) {
        print(
            'RecordingDriveSyncManager: Manually cleaning up orphaned public recordings...');
      }

      final cleanedUpCount =
          await _recordingService.validateAndCleanupOrphanedPublicRecordings();

      if (kDebugMode) {
        print(
            'RecordingDriveSyncManager: Manual cleanup completed. Cleaned up $cleanedUpCount orphaned recordings');
      }

      return cleanedUpCount;
    } catch (e) {
      if (kDebugMode) {
        print('RecordingDriveSyncManager: Error during manual cleanup: $e');
      }
      return 0;
    }
  }

  /// Manual refresh of recordings
  Future<void> refreshRecordings() async {
    try {
      if (kDebugMode) {
        print('RecordingDriveSyncManager: Manually refreshing recordings...');
      }

      _stateManager.lastError.value = '';

      // Always load local recordings first
      await _recordingService.loadRecordings();

      // Fix recordings with unknown hymnId
      await fixUnknownHymnIds();

      // Clean up ghost recordings
      await cleanupGhostRecordings();

      // Update recordings with 0 duration
      await updateRecordingDurations();

      // Force sync from Drive if signed in
      if (_authManager.isDriveSignedIn.value) {
        await syncFromDrive(force: true);
      }
    } catch (e) {
      if (kDebugMode) {
        print('RecordingDriveSyncManager: Error refreshing recordings: $e');
      }
      _stateManager.lastError.value = 'Refresh failed: $e';
    }
  }

  /// Update recordings with 0 duration by fetching actual duration
  Future<void> updateRecordingDurations() async {
    try {
      final recordings = _recordingService.recordings;
      int updatedCount = 0;

      for (final recording in recordings) {
        // Only update recordings that have 0 duration
        if (recording.durationSeconds == 0) {
          try {
            int actualDuration = 0;

            // First try to get duration from local file if it exists
            if (recording.filePath.isNotEmpty) {
              actualDuration =
                  await AudioService.getAudioFileDuration(recording.filePath);
              if (kDebugMode && actualDuration > 0) {
                debugPrint(
                    'RecordingDriveSyncManager: Got duration from local file for ${recording.title}: ${actualDuration}s');
              }
            }

            // If local file didn't work or doesn't exist, try Drive
            if (actualDuration == 0 && recording.driveFileId != null) {
              final downloadUrl = recording.publicLink ??
                  'https://drive.google.com/uc?export=download&id=${recording.driveFileId}';
              actualDuration =
                  await AudioService.getAudioUrlDuration(downloadUrl);
              if (kDebugMode && actualDuration > 0) {
                debugPrint(
                    'RecordingDriveSyncManager: Got duration from Drive for ${recording.title}: ${actualDuration}s');
              }
            }

            if (actualDuration > 0) {
              final updatedRecording = recording.copyWith(
                durationSeconds: actualDuration,
              );

              await _recordingService.updateRecording(updatedRecording);
              updatedCount++;

              if (kDebugMode) {
                print(
                    'RecordingDriveSyncManager: Updated duration for ${recording.title}: ${actualDuration}s');
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print(
                  'RecordingDriveSyncManager: Could not update duration for ${recording.title}: $e');
            }
          }
        }
      }

      if (updatedCount > 0) {
        await _recordingService.loadRecordings();
        if (kDebugMode) {
          print(
              'RecordingDriveSyncManager: Updated durations for $updatedCount recordings');
        }
      } else {
        if (kDebugMode) {
          print(
              'RecordingDriveSyncManager: No recordings needed duration updates');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            'RecordingDriveSyncManager: Error updating recording durations: $e');
      }
    }
  }

  /// Clean up ghost recordings (0 duration, no file, but marked as uploaded)
  Future<void> cleanupGhostRecordings() async {
    try {
      final ghostsToRemove = <UserRecording>[];

      for (final recording in recordings) {
        if (recording.durationSeconds == 0 &&
            recording.filePath.isEmpty &&
            recording.driveFileId != null &&
            recording.hymnId == 'unknown') {
          ghostsToRemove.add(recording);
          if (kDebugMode) {
            print(
                'RecordingDriveSyncManager: Found ghost recording to remove: ${recording.title} (ID: ${recording.id})');
          }
        }
      }

      for (final ghost in ghostsToRemove) {
        await _recordingService.deleteLocalRecording(ghost.id);
        if (kDebugMode) {
          print(
              'RecordingDriveSyncManager: Removed ghost recording: ${ghost.title}');
        }
      }

      if (ghostsToRemove.isNotEmpty) {
        await _recordingService.loadRecordings();
        if (kDebugMode) {
          print(
              'RecordingDriveSyncManager: Cleaned up ${ghostsToRemove.length} ghost recordings');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            'RecordingDriveSyncManager: Error cleaning up ghost recordings: $e');
      }
    }
  }

  /// Fix recordings with unknown hymnId by extracting from filename
  Future<void> fixUnknownHymnIds() async {
    try {
      bool needsUpdate = false;
      final updatedRecordings = <UserRecording>[];

      for (final recording in recordings) {
        if (recording.hymnId == 'unknown') {
          String newHymnId = 'unknown';

          final title = recording.title;
          final numberMatch = RegExp(r'(\d+)').firstMatch(title);
          if (numberMatch != null) {
            newHymnId = numberMatch.group(1)!;
          }

          if (newHymnId != recording.hymnId) {
            final updated = recording.copyWith(hymnId: newHymnId);
            updatedRecordings.add(updated);
            needsUpdate = true;

            if (kDebugMode) {
              print(
                  'RecordingDriveSyncManager: Fixed hymnId for recording "${recording.title}": ${recording.hymnId} -> $newHymnId');
            }
          }
        }
      }

      if (needsUpdate) {
        for (final updated in updatedRecordings) {
          await _recordingService.updateRecording(updated);
        }
        if (kDebugMode) {
          print(
              'RecordingDriveSyncManager: Updated ${updatedRecordings.length} recordings with corrected hymnId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('RecordingDriveSyncManager: Error fixing unknown hymnIds: $e');
      }
    }
  }

  /// Enhanced sync from Drive with better error handling
  Future<void> syncFromDrive({bool force = false}) async {
    if (kDebugMode) {
      print('RecordingDriveSyncManager: syncFromDrive() called (force=$force)');
      print(
          'RecordingDriveSyncManager: isDriveSignedIn = ${_authManager.isDriveSignedIn.value}');
    }

    if (!_authManager.isDriveSignedIn.value) {
      if (kDebugMode) {
        print(
            'RecordingDriveSyncManager: Cannot sync from Drive: Not signed in');
      }
      return;
    }

    if (!force && _stateManager.isLoading.value) {
      if (kDebugMode) {
        print('RecordingDriveSyncManager: Sync already in progress, skipping');
      }
      return;
    }

    try {
      _stateManager.isLoading.value = true;
      _stateManager.lastError.value = '';

      if (kDebugMode) {
        print(
            'RecordingDriveSyncManager: Calling driveService.listRecordings()...');
      }

      final driveService = _authManager.driveService;
      if (driveService == null) {
        throw Exception('Drive service is null');
      }

      final driveFiles = await driveService.listRecordings();

      if (kDebugMode) {
        print(
            'RecordingDriveSyncManager: Found ${driveFiles.length} files in Drive');
        for (final file in driveFiles.take(5)) {
          print('  - ${file.name} (ID: ${file.id}, Type: ${file.mimeType})');
        }
        if (driveFiles.length > 5) {
          print('  ... and ${driveFiles.length - 5} more');
        }
      }

      // Create a map of existing recordings by drive file ID for quick lookup
      final existingByDriveId = <String, UserRecording>{};
      for (final recording in recordings) {
        if (recording.driveFileId != null) {
          existingByDriveId[recording.driveFileId!] = recording;
        }
      }

      int newRecordingsCount = 0;
      int updatedRecordingsCount = 0;

      // Check for files in Drive that aren't in local recordings
      for (final driveFile in driveFiles) {
        if (driveFile.mimeType == 'application/vnd.google-apps.folder') {
          continue;
        }

        if (driveFile.id == null) {
          if (kDebugMode) {
            print(
                'RecordingDriveSyncManager: Skipping file with null ID: ${driveFile.name}');
          }
          continue;
        }

        if (!existingByDriveId.containsKey(driveFile.id!)) {
          final fileName = (driveFile.name ?? '')
              .replaceAll('.m4a', '')
              .replaceAll('.mp3', '');

          String hymnId = 'unknown';
          if (driveFile.description != null &&
              driveFile.description!.contains('Hymn:')) {
            final parts = driveFile.description!.split('Hymn: ');
            if (parts.length > 1) {
              final extractedId = parts.last.trim();
              if (RegExp(r'^\d+$').hasMatch(extractedId)) {
                hymnId = extractedId;
              }
            }
          }

          if (hymnId == 'unknown') {
            final numberMatch = RegExp(r'(\d+)').firstMatch(fileName);
            if (numberMatch != null) {
              hymnId = numberMatch.group(1)!;
            }
          }

          final driveCreatedTime =
              DateTime.tryParse(driveFile.createdTime?.toString() ?? '') ??
                  DateTime.now();

          final existingLocalRecording = recordings.firstWhereOrNull((r) =>
              r.title == fileName &&
              r.driveFileId == null &&
              (r.createdAt.difference(driveCreatedTime).inSeconds.abs() < 300));

          if (existingLocalRecording != null) {
            final updated = existingLocalRecording.copyWith(
              driveFileId: driveFile.id,
              driveWebLink: driveFile.webViewLink,
              publicLink: existingLocalRecording.isPublic
                  ? driveFile.webContentLink
                  : existingLocalRecording.publicLink,
            );
            await _recordingService.updateRecording(updated);
            updatedRecordingsCount++;

            if (kDebugMode) {
              print(
                  'RecordingDriveSyncManager: Updated existing recording with Drive info: ${existingLocalRecording.title}');
            }
          } else {
            // Try to get the actual duration from the Drive file
            int durationSeconds = 0;
            try {
              final downloadUrl = driveFile.webContentLink ??
                  'https://drive.google.com/uc?export=download&id=${driveFile.id}';
              durationSeconds =
                  await AudioService.getAudioUrlDuration(downloadUrl);
              if (kDebugMode) {
                print(
                    'RecordingDriveSyncManager: Retrieved duration for $fileName: ${durationSeconds}s');
              }
            } catch (e) {
              if (kDebugMode) {
                print(
                    'RecordingDriveSyncManager: Could not get duration for $fileName: $e');
              }
            }

            final recording = UserRecording(
              id: _uuid.v4(),
              hymnId: hymnId,
              title: fileName,
              filePath: '',
              durationSeconds: durationSeconds,
              createdAt: driveCreatedTime,
              isPublic: false,
              tags: [],
              driveFileId: driveFile.id ?? '',
              driveWebLink: driveFile.webViewLink,
              publicLink: driveFile.webContentLink,
            );

            await _recordingService.saveDriveRecording(recording);
            newRecordingsCount++;

            if (kDebugMode) {
              print(
                  'RecordingDriveSyncManager: Added new recording from Drive: ${recording.title} (Hymn: $hymnId, Duration: ${durationSeconds}s)');
            }
          }
        }
      }

      // Check for local recordings that have Drive files but the Drive file no longer exists
      for (final recording in recordings) {
        if (recording.driveFileId != null) {
          final driveFileExists =
              driveFiles.any((f) => f.id == recording.driveFileId);
          if (!driveFileExists) {
            final updated = recording.copyWith(
              driveFileId: null,
              driveWebLink: null,
            );
            await _recordingService.updateRecording(updated);

            if (kDebugMode) {
              print(
                  'RecordingDriveSyncManager: Removed Drive reference for deleted file: ${recording.title}');
            }
          }
        }
      }

      await _recordingService.loadRecordings();

      if (kDebugMode) {
        print(
            'RecordingDriveSyncManager: Drive sync completed: $newRecordingsCount new, $updatedRecordingsCount updated');
      }

      if (newRecordingsCount > 0 || updatedRecordingsCount > 0) {
        Get.snackbar(
          'Sync Complete',
          'Found $newRecordingsCount new recordings',
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          colorText: Colors.green,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('RecordingDriveSyncManager: Error syncing from Drive: $e');
        print('RecordingDriveSyncManager: Stack trace: ${StackTrace.current}');
      }
      _stateManager.lastError.value = 'Drive sync failed: $e';
      Get.snackbar(
        'Sync Failed',
        'Failed to sync recordings from Drive: ${e.toString()}',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      _stateManager.isLoading.value = false;
    }
  }

  /// Load recordings from local database
  Future<void> loadRecordings() async {
    await _recordingService.loadRecordings();
  }
}
