import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fihirana/features/recording/domain/entities/user_recording.dart';
import 'package:fihirana/features/recording/domain/usecases/recording_usecases.dart';
import 'package:fihirana/features/recording/domain/repositories/recording_repository.dart';
import 'package:fihirana/features/recording/data/repositories/recording_repository_impl.dart';
import 'recording_state_manager.dart';
import 'recording_auth_manager.dart';
import 'recording_drive_sync_manager.dart';
import 'recording_operations_manager.dart' as ops;
import 'recording_playback_manager.dart';
import 'recording_publishing_manager.dart';
import 'recording_file_manager.dart';
import 'package:flutter/foundation.dart';

// Export enums for backward compatibility
export 'recording_publishing_manager.dart' show PublishRecordingResult;

/// Main controller that coordinates all recording-related managers
/// Now uses DI pattern with use cases
class RecordingController extends GetxController {
  // Repository (injected via DI)
  final RecordingRepository repository;

  // Use cases (injected via DI)
  final StartRecordingUseCase startRecordingUseCase;
  final StopRecordingUseCase stopRecordingUseCase;
  final CancelRecordingUseCase cancelRecordingUseCase;
  final LoadRecordingsUseCase loadRecordingsUseCase;
  final SaveRecordingUseCase saveRecordingUseCase;
  final UpdateRecordingUseCase updateRecordingUseCase;
  final DeleteRecordingUseCase deleteRecordingUseCase;
  final GetRecordingByIdUseCase getRecordingByIdUseCase;
  final LoadPublicRecordingsUseCase loadPublicRecordingsUseCase;
  final PublishRecordingUseCase publishRecordingUseCase;
  final UnpublishRecordingUseCase unpublishRecordingUseCase;
  final ToggleRecordingPrivacyUseCase toggleRecordingPrivacyUseCase;
  final SearchRecordingsUseCase searchRecordingsUseCase;
  final GetRecordingsByHymnIdUseCase getRecordingsByHymnIdUseCase;
  final UploadToGoogleDriveUseCase uploadToGoogleDriveUseCase;
  final SyncFromDriveUseCase syncFromDriveUseCase;
  final LoadDeletedRecordingsUseCase loadDeletedRecordingsUseCase;
  final RestoreRecordingUseCase restoreRecordingUseCase;
  final PermanentlyDeleteRecordingUseCase permanentlyDeleteRecordingUseCase;
  final PermanentlyDeleteMultipleRecordingsUseCase
      permanentlyDeleteMultipleRecordingsUseCase;

  // Legacy managers (for backward compatibility)
  late final RecordingStateManager stateManager;
  late final RecordingAuthManager authManager;
  late final RecordingDriveSyncManager syncManager;
  late final ops.RecordingOperationsManager operationsManager;
  late final RecordingPlaybackManager playbackManager;
  late final RecordingPublishingManager publishingManager;
  late final RecordingFileManager fileManager;

  // Constructor for DI (with optional parameters for backward compatibility)
  RecordingController({
    RecordingRepository? repository,
    StartRecordingUseCase? startRecordingUseCase,
    StopRecordingUseCase? stopRecordingUseCase,
    CancelRecordingUseCase? cancelRecordingUseCase,
    LoadRecordingsUseCase? loadRecordingsUseCase,
    SaveRecordingUseCase? saveRecordingUseCase,
    UpdateRecordingUseCase? updateRecordingUseCase,
    DeleteRecordingUseCase? deleteRecordingUseCase,
    GetRecordingByIdUseCase? getRecordingByIdUseCase,
    LoadPublicRecordingsUseCase? loadPublicRecordingsUseCase,
    PublishRecordingUseCase? publishRecordingUseCase,
    UnpublishRecordingUseCase? unpublishRecordingUseCase,
    ToggleRecordingPrivacyUseCase? toggleRecordingPrivacyUseCase,
    SearchRecordingsUseCase? searchRecordingsUseCase,
    GetRecordingsByHymnIdUseCase? getRecordingsByHymnIdUseCase,
    UploadToGoogleDriveUseCase? uploadToGoogleDriveUseCase,
    SyncFromDriveUseCase? syncFromDriveUseCase,
    LoadDeletedRecordingsUseCase? loadDeletedRecordingsUseCase,
    RestoreRecordingUseCase? restoreRecordingUseCase,
    PermanentlyDeleteRecordingUseCase? permanentlyDeleteRecordingUseCase,
    PermanentlyDeleteMultipleRecordingsUseCase?
        permanentlyDeleteMultipleRecordingsUseCase,
  })  : repository = repository ?? RecordingRepositoryImpl(),
        startRecordingUseCase = startRecordingUseCase ??
            StartRecordingUseCase(repository ?? RecordingRepositoryImpl()),
        stopRecordingUseCase = stopRecordingUseCase ??
            StopRecordingUseCase(repository ?? RecordingRepositoryImpl()),
        cancelRecordingUseCase = cancelRecordingUseCase ??
            CancelRecordingUseCase(repository ?? RecordingRepositoryImpl()),
        loadRecordingsUseCase = loadRecordingsUseCase ??
            LoadRecordingsUseCase(repository ?? RecordingRepositoryImpl()),
        saveRecordingUseCase = saveRecordingUseCase ??
            SaveRecordingUseCase(repository ?? RecordingRepositoryImpl()),
        updateRecordingUseCase = updateRecordingUseCase ??
            UpdateRecordingUseCase(repository ?? RecordingRepositoryImpl()),
        deleteRecordingUseCase = deleteRecordingUseCase ??
            DeleteRecordingUseCase(repository ?? RecordingRepositoryImpl()),
        getRecordingByIdUseCase = getRecordingByIdUseCase ??
            GetRecordingByIdUseCase(repository ?? RecordingRepositoryImpl()),
        loadPublicRecordingsUseCase = loadPublicRecordingsUseCase ??
            LoadPublicRecordingsUseCase(
                repository ?? RecordingRepositoryImpl()),
        publishRecordingUseCase = publishRecordingUseCase ??
            PublishRecordingUseCase(repository ?? RecordingRepositoryImpl()),
        unpublishRecordingUseCase = unpublishRecordingUseCase ??
            UnpublishRecordingUseCase(repository ?? RecordingRepositoryImpl()),
        toggleRecordingPrivacyUseCase = toggleRecordingPrivacyUseCase ??
            ToggleRecordingPrivacyUseCase(
                repository ?? RecordingRepositoryImpl()),
        searchRecordingsUseCase = searchRecordingsUseCase ??
            SearchRecordingsUseCase(repository ?? RecordingRepositoryImpl()),
        getRecordingsByHymnIdUseCase = getRecordingsByHymnIdUseCase ??
            GetRecordingsByHymnIdUseCase(
                repository ?? RecordingRepositoryImpl()),
        uploadToGoogleDriveUseCase = uploadToGoogleDriveUseCase ??
            UploadToGoogleDriveUseCase(repository ?? RecordingRepositoryImpl()),
        syncFromDriveUseCase = syncFromDriveUseCase ??
            SyncFromDriveUseCase(repository ?? RecordingRepositoryImpl()),
        loadDeletedRecordingsUseCase = loadDeletedRecordingsUseCase ??
            LoadDeletedRecordingsUseCase(
                repository ?? RecordingRepositoryImpl()),
        restoreRecordingUseCase = restoreRecordingUseCase ??
            RestoreRecordingUseCase(repository ?? RecordingRepositoryImpl()),
        permanentlyDeleteRecordingUseCase = permanentlyDeleteRecordingUseCase ??
            PermanentlyDeleteRecordingUseCase(
                repository ?? RecordingRepositoryImpl()),
        permanentlyDeleteMultipleRecordingsUseCase =
            permanentlyDeleteMultipleRecordingsUseCase ??
                PermanentlyDeleteMultipleRecordingsUseCase(
                    repository ?? RecordingRepositoryImpl());

  // Delegated properties for backward compatibility
  // Recording state
  RxBool get isRecording => stateManager.isRecording;
  RxBool get isPaused => stateManager.isPaused;
  RxInt get recordDuration => stateManager.recordDuration;

  // Data
  RxList<UserRecording> get recordings => repository.recordings;
  RxList<UserRecording> get publicRecordings =>
      publishingManager.publicRecordings;
  RxBool get isLoading => stateManager.isLoading;
  RxBool get isUploading => stateManager.isUploading;

  // Drive state
  RxBool get isDriveSignedIn => authManager.isDriveSignedIn;
  Rxn<String> get userEmail => authManager.userEmail;
  RxString get guestName => authManager.guestName;

  // Upload state tracking
  RxSet<String> get uploadingRecordingIds => fileManager.uploadingRecordingIds;
  RxMap<String, String> get uploadErrors => fileManager.uploadErrors;

  // Overlay state management
  RxBool get isOverlayMinimized => stateManager.isOverlayMinimized;
  RxString get currentHymnId => stateManager.currentHymnId;
  RxString get currentHymnTitle => stateManager.currentHymnTitle;
  RxBool get overlayVisible => stateManager.overlayVisible;

  // Audio sharing permission
  RxBool get allowToShareAudio => authManager.allowToShareAudio;

  // Error tracking
  RxString get lastError => stateManager.lastError;

  // Player state
  RxBool get isPlayerOverlayVisible => stateManager.isPlayerOverlayVisible;
  RxBool get isPlayerMinimized => stateManager.isPlayerMinimized;
  Rxn<UserRecording> get currentRecording => playbackManager.currentRecording;

  // Storage quota
  Rxn<Map<String, dynamic>> get storageQuota {
    final quota = authManager.storageQuota.value;
    if (quota == null) return Rxn<Map<String, dynamic>>(null);

    return Rxn<Map<String, dynamic>>({
      'usage': quota.usage ?? 0,
      'limit': quota.limit ?? 0,
    });
  }

  // Multi-select state
  final RxBool isMultiSelectMode = false.obs;
  final RxSet<String> selectedRecordingIds = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeManagers();
    _loadInitialData().then((_) {
      // Start cleanup after initial data is loaded
      _cleanupOrphanedRecordingsOnStartup();
    });
  }

  void _initializeManagers() {
    // Initialize managers in dependency order (for backward compatibility)
    stateManager = Get.put(RecordingStateManager(), tag: 'recording');

    authManager = Get.put(
      RecordingAuthManager(),
      tag: 'recording',
    );

    // Note: These managers would need to be updated to use use cases
    // For now, they're kept for backward compatibility
    syncManager = Get.put(
      RecordingDriveSyncManager(
        recordingService: Get.find(),
        authManager: authManager,
        stateManager: stateManager,
      ),
      tag: 'recording',
    );

    operationsManager = Get.put(
      ops.RecordingOperationsManager(
        recordingService: repository,
        authManager: authManager,
        stateManager: stateManager,
      ),
      tag: 'recording',
    );

    playbackManager = Get.put(
      RecordingPlaybackManager(
        stateManager: stateManager,
        recordingService: Get.find(),
      ),
      tag: 'recording',
    );

    publishingManager = Get.put(
      RecordingPublishingManager(
        recordingService: Get.find(),
        authManager: authManager,
        stateManager: stateManager,
      ),
      tag: 'recording',
    );

    fileManager = Get.put(
      RecordingFileManager(
        recordingService: Get.find(),
        authManager: authManager,
        stateManager: stateManager,
      ),
      tag: 'recording',
    );
  }

  Future<void> _loadInitialData() async {
    try {
      await Future.wait([
        loadRecordingsUseCase(),
        loadPublicRecordingsUseCase(),
        loadDeletedRecordingsUseCase(),
      ]);
    } catch (e) {
      // Error loading initial data: $e
    }
  }

  /// Cleanup orphaned recordings when app starts (runs in background)
  void _cleanupOrphanedRecordingsOnStartup() async {
    try {
      if (kDebugMode) {
        print(
            'RecordingController: Starting orphaned recordings cleanup on app startup');
      }

      // Wait a bit to ensure everything is initialized
      await Future.delayed(const Duration(seconds: 3));

      // Only run cleanup if user is signed in to Drive
      if (syncManager.isDriveSignedIn.value) {
        final cleanedUpCount =
            await syncManager.cleanupOrphanedPublicRecordings();

        if (cleanedUpCount > 0) {
          if (kDebugMode) {
            print(
                'RecordingController: Cleaned up $cleanedUpCount orphaned recordings on startup');
          }

          // Show notification to user about cleanup
          Future.delayed(const Duration(seconds: 1), () {
            Get.snackbar(
              'Maintenance Complete',
              'Cleaned up $cleanedUpCount outdated recording links',
              backgroundColor: Colors.blue.shade600,
              colorText: Colors.white,
              duration: const Duration(seconds: 3),
              icon: const Icon(Icons.cleaning_services, color: Colors.white),
            );
          });
        } else {
          if (kDebugMode) {
            print(
                'RecordingController: No orphaned recordings found on startup');
          }
        }
      } else {
        if (kDebugMode) {
          print(
              'RecordingController: Skipping orphaned cleanup - user not signed in to Drive');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('RecordingController: Error during startup cleanup: $e');
      }
    }
  }

  // Delegated methods for backward compatibility
// Recording Actions (using use cases)
  Future<void> startRecording(String hymnId) async {
    try {
      await startRecordingUseCase();
      // Update state manager for backward compatibility
      stateManager.isRecording.value = true;
      stateManager.showOverlay(hymnId, '');
      stateManager.startTimer();
    } catch (e) {
      stateManager.lastError.value = 'Failed to start recording: $e';
    }
  }

  Future<UserRecording?> stopRecording(String hymnId, String title) async {
    try {
      final recording = await stopRecordingUseCase();
      if (recording != null) {
        // Set the duration from the timer
        final duration = stateManager.recordDuration.value;
        final updatedRecording = recording.copyWith(
          hymnId: hymnId,
          title: title,
          durationSeconds: duration,
        );
        await saveRecordingUseCase(updatedRecording);
        // Update state manager for backward compatibility
        stateManager.isRecording.value = false;
        // Don't hide overlay here - let the UI handle it after save dialog
        stateManager.stopTimer();
        stateManager.resetTimer();
        return updatedRecording;
      }
      return null;
    } catch (e) {
      stateManager.lastError.value = 'Failed to stop recording: $e';
      return null;
    }
  }

  Future<void> pauseRecording() async {
    await operationsManager.pauseRecording();
  }

  Future<void> resumeRecording() async {
    await operationsManager.resumeRecording();
  }

  // Standalone recording methods
  Future<void> startStandaloneRecording() =>
      operationsManager.startStandaloneRecording();

  Future<UserRecording?> stopStandaloneRecording(String title) =>
      operationsManager.stopStandaloneRecording(title);

  // Drive & Auth methods
  Future<void> signInToDrive() => authManager.signInToDrive();

  Future<void> signOutFromDrive() => authManager.signOutFromDrive();

  Future<void> checkForSilentSignIn() => authManager.checkForSilentSignIn();

  // Sync methods
  Future<void> refreshRecordings() => syncManager.refreshRecordings();

  Future<void> syncFromDrive({bool force = false}) =>
      syncManager.syncFromDrive(force: force);

// CRUD methods (using use cases)
  Future<void> updateRecording(UserRecording recording) async {
    try {
      await updateRecordingUseCase(recording);
      await operationsManager
          .updateRecording(recording); // Keep for backward compatibility
    } catch (e) {
      stateManager.lastError.value = 'Failed to update recording: $e';
    }
  }

  Future<void> deleteRecording(UserRecording recording) async {
    try {
      if (kDebugMode) {
        print(
            'RecordingController: deleteRecording called for recording: ${recording.id} - ${recording.title}');
      }

      // Check if user is the owner of the recording
      final currentUser = FirebaseAuth.instance.currentUser;
      final isOwner = (currentUser != null &&
              (recording.userId == currentUser.uid ||
                  recording.userEmail == currentUser.email)) ||
          (userEmail.value != null && recording.userEmail == userEmail.value);

      if (kDebugMode) {
        print(
            'RecordingController: currentUser=${currentUser?.uid}, recording.userId=${recording.userId}, recording.userEmail=${recording.userEmail}, controller.userEmail=${userEmail.value}');
      }
      if (kDebugMode) {
        print('RecordingController: isOwner=$isOwner');
      }

      // For debugging, if no owner info, assume owner
      if (recording.userId == null || recording.userId!.isEmpty) {
        if (kDebugMode) {
          print(
              'RecordingController: No userId found, assuming owner for debugging');
        }
        // isOwner = true; // Uncomment this line for debugging
      }

      // For debugging, just remove from the list directly
      if (kDebugMode) {
        print('RecordingController: Removing recording from list directly');
      }
      final initialLength = repository.recordings.length;
      repository.recordings.removeWhere((r) => r.id == recording.id);
      final finalLength = repository.recordings.length;
      if (kDebugMode) {
        print(
            'RecordingController: Recording removed from list: $initialLength -> $finalLength');
      }

      // Also try to delete the file if owner
      if (isOwner) {
        if (kDebugMode) {
          print(
              'RecordingController: Owner detected, attempting file deletion');
        }
        try {
          // This is a simplified approach - just remove from list for now
          // File deletion can be handled separately
        } catch (e) {
          if (kDebugMode) {
            print('RecordingController: Error deleting file: $e');
          }
        }
      }

      if (kDebugMode) {
        print(
            'RecordingController: Recordings list length after delete: ${repository.recordings.length}');
      }

      // Force UI refresh by triggering reactive update
      repository.recordings.refresh();
      update();
    } catch (e) {
      if (kDebugMode) {
        print('RecordingController: Error deleting recording: $e');
      }
      stateManager.lastError.value = 'Failed to delete recording: $e';
    }
  }

  Future<void> deleteRecordingPermanentlyDirect(UserRecording recording) =>
      operationsManager.deleteRecordingPermanentlyDirect(recording);

  Future<void> moveRecordingToTrash(UserRecording recording) =>
      operationsManager.moveRecordingToTrash(recording);

  Future<void> renameRecording(UserRecording recording, String newTitle) =>
      operationsManager.renameRecording(recording, newTitle);

  // Playback methods
  Future<void> playRecording(UserRecording recording) =>
      playbackManager.playRecording(recording);

  Future<void> pausePlayback() => playbackManager.pausePlayback();

  Future<void> resumePlayback() => playbackManager.resumePlayback();

  Future<void> stopPlayback() => playbackManager.stopPlayback();

  Future<void> seekPlayback(Duration position) =>
      playbackManager.seekPlayback(position);

// Public recording methods (using use cases)
  Future<List<UserRecording>> loadPublicRecordings({String? hymnId}) async {
    try {
      await loadPublicRecordingsUseCase();
      return publishingManager.loadPublicRecordings(
          hymnId: hymnId); // Keep for backward compatibility
    } catch (e) {
      stateManager.lastError.value = 'Failed to load public recordings: $e';
      return [];
    }
  }

  Future<void> refreshPublicRecordings({String? hymnId}) async {
    try {
      await loadPublicRecordingsUseCase();
      await publishingManager.refreshPublicRecordings(
          hymnId: hymnId); // Keep for backward compatibility
    } catch (e) {
      stateManager.lastError.value = 'Failed to refresh public recordings: $e';
    }
  }

  /// Manual cleanup of orphaned public recordings
  Future<int> cleanupOrphanedPublicRecordings() async {
    try {
      if (kDebugMode) {
        print(
            'RecordingController: Starting manual cleanup of orphaned recordings');
      }

      final cleanedUpCount =
          await syncManager.cleanupOrphanedPublicRecordings();

      if (kDebugMode) {
        print(
            'RecordingController: Cleanup completed, cleaned up $cleanedUpCount recordings');
      }

      // Force refresh public recordings to update UI
      if (kDebugMode) {
        print(
            'RecordingController: Refreshing public recordings after cleanup');
        print(
            'RecordingController: Public recordings before refresh: ${publicRecordings.length}');
      }

      await loadPublicRecordingsUseCase();
      await publishingManager.refreshPublicRecordings();

      // Force UI update by triggering reactive update
      publicRecordings.refresh();

      if (kDebugMode) {
        print('RecordingController: Public recordings refresh completed');
        print(
            'RecordingController: Current public recordings count: ${publicRecordings.length}');
        print(
            'RecordingController: Publishing manager recordings count: ${publishingManager.publicRecordings.length}');
      }

      if (cleanedUpCount > 0) {
        Get.snackbar(
          'Cleanup Complete',
          'Cleaned up $cleanedUpCount orphaned public recordings',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          'Cleanup Complete',
          'No orphaned recordings found',
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }

      return cleanedUpCount;
    } catch (e) {
      if (kDebugMode) {
        print('RecordingController: Error during cleanup: $e');
      }
      stateManager.lastError.value =
          'Failed to cleanup orphaned recordings: $e';
      Get.snackbar(
        'Cleanup Failed',
        'Failed to cleanup orphaned recordings: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return 0;
    }
  }

  /// Validate a specific recording's Drive file existence
  Future<bool> validateRecordingFile(String recordingId) async {
    try {
      return await repository.validateRecordingFile(recordingId);
    } catch (e) {
      if (kDebugMode) {
        print('RecordingController: Error validating recording file: $e');
      }
      return false;
    }
  }

  /// Check how many orphaned recordings exist
  Future<int> checkOrphanedRecordings() async {
    try {
      final count = await repository.checkOrphanedPublicRecordings();
      if (kDebugMode) {
        print('RecordingController: Found $count orphaned recordings');
      }
      return count;
    } catch (e) {
      if (kDebugMode) {
        print('RecordingController: Error checking orphaned recordings: $e');
      }
      return 0;
    }
  }

  /// Test cleanup functionality - check before and after
  Future<void> testCleanupFunctionality() async {
    try {
      if (kDebugMode) {
        print('RecordingController: Testing cleanup functionality');
      }

      // Check orphaned count before cleanup
      final orphanedBefore = await checkOrphanedRecordings();
      if (kDebugMode) {
        print(
            'RecordingController: Orphaned recordings before cleanup: $orphanedBefore');
        print(
            'RecordingController: Public recordings in UI before cleanup: ${publicRecordings.length}');
      }

      // Run cleanup
      final cleanedUpCount = await cleanupOrphanedPublicRecordings();

      // Check orphaned count after cleanup
      final orphanedAfter = await checkOrphanedRecordings();
      if (kDebugMode) {
        print(
            'RecordingController: Orphaned recordings after cleanup: $orphanedAfter');
        print('RecordingController: Cleaned up: $cleanedUpCount');
        print(
            'RecordingController: Public recordings in UI after cleanup: ${publicRecordings.length}');
      }

      // Show detailed results
      Get.snackbar(
        'Cleanup Test Results',
        'Before: $orphanedBefore orphaned, After: $orphanedAfter orphaned, Cleaned: $cleanedUpCount',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      if (kDebugMode) {
        print('RecordingController: Error testing cleanup: $e');
      }
      Get.snackbar(
        'Test Failed',
        'Error testing cleanup: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Force refresh all recordings and run cleanup
  Future<void> forceRefreshAndCleanup() async {
    try {
      if (kDebugMode) {
        print('RecordingController: Force refresh and cleanup triggered');
      }

      // Load all data
      await Future.wait([
        loadRecordingsUseCase(),
        loadPublicRecordingsUseCase(),
        loadDeletedRecordingsUseCase(),
      ]);

      // Run cleanup
      await cleanupOrphanedPublicRecordings();

      Get.snackbar(
        'Refresh Complete',
        'All recordings refreshed and orphaned links cleaned up',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      if (kDebugMode) {
        print(
            'RecordingController: Error during force refresh and cleanup: $e');
      }
      Get.snackbar(
        'Refresh Failed',
        'Failed to refresh and cleanup: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Force refresh UI without cleanup
  Future<void> forceRefreshUI() async {
    try {
      if (kDebugMode) {
        print('RecordingController: Force refresh UI triggered');
        print(
            'RecordingController: Public recordings before refresh: ${publicRecordings.length}');
      }

      // Force refresh public recordings
      await loadPublicRecordingsUseCase();
      await publishingManager.refreshPublicRecordings();
      publicRecordings.refresh();

      if (kDebugMode) {
        print(
            'RecordingController: Public recordings after refresh: ${publicRecordings.length}');
      }

      Get.snackbar(
        'UI Refreshed',
        'Public recordings list refreshed',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      if (kDebugMode) {
        print('RecordingController: Error refreshing UI: $e');
      }
      Get.snackbar(
        'Refresh Failed',
        'Failed to refresh UI: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<PublishRecordingResult> makeRecordingPublic(UserRecording recording,
          {String? customTitle}) =>
      publishingManager.makeRecordingPublic(recording,
          customTitle: customTitle);

  Future<void> publishRecording(UserRecording recording) async {
    try {
      await publishRecordingUseCase(recording);
      await publishingManager
          .publishRecording(recording); // Keep for backward compatibility
    } catch (e) {
      stateManager.lastError.value = 'Failed to publish recording: $e';
    }
  }

  Future<void> unpublishRecording(UserRecording recording) async {
    try {
      await unpublishRecordingUseCase(recording.id);
      await publishingManager
          .unpublishRecording(recording); // Keep for backward compatibility
    } catch (e) {
      stateManager.lastError.value = 'Failed to unpublish recording: $e';
    }
  }

  // File management methods
  bool isUploadingRecording(String recordingId) =>
      fileManager.isUploadingRecording(recordingId);

  String? getUploadError(String recordingId) =>
      fileManager.getUploadError(recordingId);

  Future<void> retryUpload(UserRecording recording) =>
      fileManager.retryUpload(recording);

  Future<void> uploadToDrive(UserRecording recording) =>
      fileManager.uploadToDrive(recording);

  Future<void> reuploadToDrive(UserRecording recording) =>
      fileManager.reuploadToDrive(recording);

  Future<void> downloadRecording(UserRecording recording) =>
      fileManager.downloadRecording(recording);

  Future<void> shareRecordingFile(UserRecording recording) =>
      fileManager.shareRecordingFile(recording);

  Future<void> exportRecording(UserRecording recording) =>
      fileManager.exportRecording(recording);

  // Deleted recordings management
  Future<List<UserRecording>> getDeletedRecordings() =>
      operationsManager.getDeletedRecordings();

  Future<void> restoreRecording(UserRecording deletedRecording) =>
      operationsManager.restoreRecording(deletedRecording);

  Future<void> permanentlyDeleteRecording(UserRecording deletedRecording) =>
      operationsManager.permanentlyDeleteRecording(deletedRecording);

  // Overlay methods
  void showOverlay(String hymnId, String title) =>
      stateManager.showOverlay(hymnId, title);

  void hideOverlay() => stateManager.hideOverlay();

  void minimizeOverlay() => stateManager.minimizeOverlay();

  void maximizeOverlay() => stateManager.restoreOverlay();

  void showPlayerOverlay(UserRecording recording) =>
      stateManager.showPlayerOverlay();

  void hidePlayerOverlay() => stateManager.hidePlayerOverlay();

  void minimizePlayer() => stateManager.minimizePlayer();

  void maximizePlayer() => stateManager.restorePlayer();

  // Additional delegation methods for backward compatibility
  void setGuestName(String name) => authManager.setGuestName(name);

  void onPageVisible() {
    syncManager.loadRecordings();
    publishingManager.refreshPublicRecordings();
  }

  bool shouldShowOverlay() => stateManager.shouldShowOverlay();

  void restoreOverlay() => stateManager.restoreOverlay();

  void showPlayer(UserRecording recording,
          {required bool isRecording, required VoidCallback onStopRecording}) =>
      playbackManager.showPlayer(recording,
          isRecording: isRecording, onStopRecording: onStopRecording);

  // Multi-select methods
  void enableMultiSelectMode() {
    if (kDebugMode) {
      print('RecordingController: Enabling multi-select mode');
    }
    isMultiSelectMode.value = true;
    selectedRecordingIds.clear();
  }

  void disableMultiSelectMode() {
    if (kDebugMode) {
      print('RecordingController: Disabling multi-select mode');
    }
    isMultiSelectMode.value = false;
    selectedRecordingIds.clear();
  }

  void toggleRecordingSelection(String recordingId) {
    if (selectedRecordingIds.contains(recordingId)) {
      selectedRecordingIds.remove(recordingId);
      if (kDebugMode) {
        print(
            'RecordingController: Deselected recording: $recordingId, selected count: ${selectedRecordingIds.length}');
      }
    } else {
      selectedRecordingIds.add(recordingId);
      if (kDebugMode) {
        print(
            'RecordingController: Selected recording: $recordingId, selected count: ${selectedRecordingIds.length}');
      }
    }
  }

  void selectAllRecordings(List<UserRecording> recordings) {
    selectedRecordingIds.addAll(recordings.map((r) => r.id));
  }

  void clearSelection() {
    selectedRecordingIds.clear();
  }

  Future<void> permanentlyDeleteSelectedRecordings() async {
    if (kDebugMode) {
      print(
          'RecordingController: permanentlyDeleteSelectedRecordings called with ${selectedRecordingIds.length} recordings');
    }
    if (selectedRecordingIds.isEmpty) {
      if (kDebugMode) {
        print('RecordingController: No recordings selected');
      }
      return;
    }

    // Get the recordings to delete
    final allRecordings = repository.recordings;
    final recordingsToDelete = selectedRecordingIds
        .map((id) => allRecordings.firstWhereOrNull((r) => r.id == id))
        .where((r) => r != null)
        .cast<UserRecording>()
        .toList();

    if (kDebugMode) {
      print(
          'RecordingController: Found ${recordingsToDelete.length} recordings to delete');
    }

    // Separate public and private recordings
    final publicRecordings =
        recordingsToDelete.where((r) => r.isPublic).toList();
    final privateRecordings =
        recordingsToDelete.where((r) => !r.isPublic).toList();

    if (kDebugMode) {
      print(
          'RecordingController: Public recordings: ${publicRecordings.length}, Private recordings: ${privateRecordings.length}');
    }

    // Handle public recordings - unpublish them
    for (final recording in publicRecordings) {
      if (kDebugMode) {
        print(
            'RecordingController: Unpublishing public recording: ${recording.id} - ${recording.title} (driveFileId: ${recording.driveFileId})');
      }
      try {
        await unpublishRecordingUseCase(recording.id);
        if (kDebugMode) {
          print('RecordingController: Unpublished recording: ${recording.id}');
        }

        // Also remove from local recordings list since it's no longer public
        repository.recordings.removeWhere((r) => r.id == recording.id);
        if (kDebugMode) {
          print('RecordingController: Removed from local recordings list');
        }
      } catch (e) {
        if (kDebugMode) {
          print('RecordingController: Error unpublishing recording: $e');
        }
      }
    }

    // Handle private recordings - permanently delete them
    for (final recording in privateRecordings) {
      if (kDebugMode) {
        print(
            'RecordingController: Permanently deleting private recording: ${recording.id} - ${recording.title}');
      }
      await operationsManager.deleteRecordingPermanentlyDirect(recording);
      if (kDebugMode) {
        print(
            'RecordingController: Permanently deleted recording: ${recording.id}');
      }
    }

    if (kDebugMode) {
      print('RecordingController: Finished processing all selected recordings');
    }

    // Force UI refresh
    repository.recordings.refresh();
    update();

    disableMultiSelectMode();
  }
}
