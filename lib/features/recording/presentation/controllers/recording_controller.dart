import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/recording/domain/entities/user_recording.dart';
import 'package:fihirana/features/recording/domain/usecases/recording_usecases.dart';
import 'package:fihirana/features/recording/data/repositories/recording_repository_impl.dart';
import 'recording_state_manager.dart';
import 'recording_auth_manager.dart';
import 'recording_drive_sync_manager.dart';
import 'recording_operations_manager.dart';
import 'recording_playback_manager.dart';
import 'recording_publishing_manager.dart';
import 'recording_file_manager.dart';
import 'package:flutter/foundation.dart';

// Export enums for backward compatibility
export 'recording_publishing_manager.dart'
    show PublishRecordingResult;

/// Main controller that coordinates all recording-related managers
/// Now uses DI pattern with use cases
class RecordingController extends GetxController {
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
  final PermanentlyDeleteMultipleRecordingsUseCase permanentlyDeleteMultipleRecordingsUseCase;

  // Legacy managers (for backward compatibility)
  late final RecordingStateManager stateManager;
  late final RecordingAuthManager authManager;
  late final RecordingDriveSyncManager syncManager;
  late final RecordingOperationsManager operationsManager;
  late final RecordingPlaybackManager playbackManager;
  late final RecordingPublishingManager publishingManager;
  late final RecordingFileManager fileManager;

  // Constructor for DI (with optional parameters for backward compatibility)
  RecordingController({
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
    PermanentlyDeleteMultipleRecordingsUseCase? permanentlyDeleteMultipleRecordingsUseCase,
  })  : startRecordingUseCase = startRecordingUseCase ?? StartRecordingUseCase(RecordingRepositoryImpl()),
        stopRecordingUseCase = stopRecordingUseCase ?? StopRecordingUseCase(RecordingRepositoryImpl()),
        cancelRecordingUseCase = cancelRecordingUseCase ?? CancelRecordingUseCase(RecordingRepositoryImpl()),
        loadRecordingsUseCase = loadRecordingsUseCase ?? LoadRecordingsUseCase(RecordingRepositoryImpl()),
        saveRecordingUseCase = saveRecordingUseCase ?? SaveRecordingUseCase(RecordingRepositoryImpl()),
        updateRecordingUseCase = updateRecordingUseCase ?? UpdateRecordingUseCase(RecordingRepositoryImpl()),
        deleteRecordingUseCase = deleteRecordingUseCase ?? DeleteRecordingUseCase(RecordingRepositoryImpl()),
        getRecordingByIdUseCase = getRecordingByIdUseCase ?? GetRecordingByIdUseCase(RecordingRepositoryImpl()),
        loadPublicRecordingsUseCase = loadPublicRecordingsUseCase ?? LoadPublicRecordingsUseCase(RecordingRepositoryImpl()),
        publishRecordingUseCase = publishRecordingUseCase ?? PublishRecordingUseCase(RecordingRepositoryImpl()),
        unpublishRecordingUseCase = unpublishRecordingUseCase ?? UnpublishRecordingUseCase(RecordingRepositoryImpl()),
        toggleRecordingPrivacyUseCase = toggleRecordingPrivacyUseCase ?? ToggleRecordingPrivacyUseCase(RecordingRepositoryImpl()),
        searchRecordingsUseCase = searchRecordingsUseCase ?? SearchRecordingsUseCase(RecordingRepositoryImpl()),
        getRecordingsByHymnIdUseCase = getRecordingsByHymnIdUseCase ?? GetRecordingsByHymnIdUseCase(RecordingRepositoryImpl()),
        uploadToGoogleDriveUseCase = uploadToGoogleDriveUseCase ?? UploadToGoogleDriveUseCase(RecordingRepositoryImpl()),
        syncFromDriveUseCase = syncFromDriveUseCase ?? SyncFromDriveUseCase(RecordingRepositoryImpl()),
        loadDeletedRecordingsUseCase = loadDeletedRecordingsUseCase ?? LoadDeletedRecordingsUseCase(RecordingRepositoryImpl()),
        restoreRecordingUseCase = restoreRecordingUseCase ?? RestoreRecordingUseCase(RecordingRepositoryImpl()),
        permanentlyDeleteRecordingUseCase = permanentlyDeleteRecordingUseCase ?? PermanentlyDeleteRecordingUseCase(RecordingRepositoryImpl()),
        permanentlyDeleteMultipleRecordingsUseCase = permanentlyDeleteMultipleRecordingsUseCase ?? PermanentlyDeleteMultipleRecordingsUseCase(RecordingRepositoryImpl());

  // Delegated properties for backward compatibility
  // Recording state
  RxBool get isRecording => stateManager.isRecording;
  RxBool get isPaused => stateManager.isPaused;
  RxInt get recordDuration => stateManager.recordDuration;

  // Data
  RxList<UserRecording> get recordings => syncManager.recordings;
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
    _loadInitialData();
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
      RecordingOperationsManager(
        recordingService: Get.find(),
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
        final updatedRecording = recording.copyWith(
          hymnId: hymnId,
          title: title,
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
      await operationsManager.updateRecording(recording); // Keep for backward compatibility
    } catch (e) {
      stateManager.lastError.value = 'Failed to update recording: $e';
    }
  }

  Future<void> deleteRecording(UserRecording recording) async {
    try {
      await deleteRecordingUseCase(recording.id);
      // Note: operationsManager.deleteRecording is not called here to avoid double deletion
      // The use case handles the deletion properly
    } catch (e) {
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
      return publishingManager.loadPublicRecordings(hymnId: hymnId); // Keep for backward compatibility
    } catch (e) {
      stateManager.lastError.value = 'Failed to load public recordings: $e';
      return [];
    }
  }

  Future<void> refreshPublicRecordings({String? hymnId}) async {
    try {
      await loadPublicRecordingsUseCase();
      await publishingManager.refreshPublicRecordings(hymnId: hymnId); // Keep for backward compatibility
    } catch (e) {
      stateManager.lastError.value = 'Failed to refresh public recordings: $e';
    }
  }

  Future<PublishRecordingResult> makeRecordingPublic(UserRecording recording,
          {String? customTitle}) =>
      publishingManager.makeRecordingPublic(recording,
          customTitle: customTitle);

  Future<void> publishRecording(UserRecording recording) async {
    try {
      await publishRecordingUseCase(recording);
      await publishingManager.publishRecording(recording); // Keep for backward compatibility
    } catch (e) {
      stateManager.lastError.value = 'Failed to publish recording: $e';
    }
  }

  Future<void> unpublishRecording(UserRecording recording) async {
    try {
      await unpublishRecordingUseCase(recording.id);
      await publishingManager.unpublishRecording(recording); // Keep for backward compatibility
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
    isMultiSelectMode.value = true;
    selectedRecordingIds.clear();
  }

  void disableMultiSelectMode() {
    isMultiSelectMode.value = false;
    selectedRecordingIds.clear();
  }

  void toggleRecordingSelection(String recordingId) {
    if (selectedRecordingIds.contains(recordingId)) {
      selectedRecordingIds.remove(recordingId);
    } else {
      selectedRecordingIds.add(recordingId);
    }
  }

  void selectAllRecordings(List<UserRecording> recordings) {
    selectedRecordingIds.addAll(recordings.map((r) => r.id));
  }

  void clearSelection() {
    selectedRecordingIds.clear();
  }

  Future<void> permanentlyDeleteSelectedRecordings() async {
    if (selectedRecordingIds.isEmpty) return;

    final idsToDelete = selectedRecordingIds.toList();
    await permanentlyDeleteMultipleRecordingsUseCase(idsToDelete);
    disableMultiSelectMode();
  }
}
