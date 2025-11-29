import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_recording.dart';
import '../services/user_recording_service.dart';
import '../services/public_recording_service.dart';
import '../services/deleted_recording_service.dart';
import 'recording/recording_state_manager.dart';
import 'recording/recording_auth_manager.dart';
import 'recording/recording_drive_sync_manager.dart';
import 'recording/recording_operations_manager.dart';
import 'recording/recording_playback_manager.dart';
import 'recording/recording_publishing_manager.dart';
import 'recording/recording_file_manager.dart';

// Export enums for backward compatibility
export 'recording/recording_publishing_manager.dart'
    show PublishRecordingResult;

/// Main controller that coordinates all recording-related managers
class RecordingController extends GetxController {
  // Services
  final UserRecordingService _recordingService = UserRecordingService();
  final PublicRecordingService _publicService = PublicRecordingService();
  final DeletedRecordingService _deletedService = DeletedRecordingService();

  // Managers
  late final RecordingStateManager stateManager;
  late final RecordingAuthManager authManager;
  late final RecordingDriveSyncManager syncManager;
  late final RecordingOperationsManager operationsManager;
  late final RecordingPlaybackManager playbackManager;
  late final RecordingPublishingManager publishingManager;
  late final RecordingFileManager fileManager;

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
  get storageQuota => authManager.storageQuota;

  @override
  void onInit() {
    super.onInit();
    _initializeManagers();
  }

  void _initializeManagers() {
    // Initialize managers in dependency order
    stateManager = Get.put(RecordingStateManager(), tag: 'recording');

    authManager = Get.put(
      RecordingAuthManager(),
      tag: 'recording',
    );

    syncManager = Get.put(
      RecordingDriveSyncManager(
        recordingService: _recordingService,
        authManager: authManager,
        stateManager: stateManager,
      ),
      tag: 'recording',
    );

    operationsManager = Get.put(
      RecordingOperationsManager(
        recordingService: _recordingService,
        deletedService: _deletedService,
        authManager: authManager,
        stateManager: stateManager,
      ),
      tag: 'recording',
    );

    playbackManager = Get.put(
      RecordingPlaybackManager(
        stateManager: stateManager,
      ),
      tag: 'recording',
    );

    publishingManager = Get.put(
      RecordingPublishingManager(
        recordingService: _recordingService,
        publicService: _publicService,
        authManager: authManager,
        stateManager: stateManager,
      ),
      tag: 'recording',
    );

    fileManager = Get.put(
      RecordingFileManager(
        recordingService: _recordingService,
        authManager: authManager,
        stateManager: stateManager,
      ),
      tag: 'recording',
    );

    // Set up auth listener
    _setupAuthListener();

    // Set up callback for Drive sign-in success
    authManager.onDriveSignInSuccess = () async {
      if (authManager.isDriveSignedIn.value) {
        await syncManager.syncFromDrive();
      }
    };

    // Load initial data
    _loadInitialData();
  }

  void _setupAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        if (kDebugMode) {
          print(
              'RecordingController: Firebase user logged in, checking Drive status...');
        }
        Future.delayed(const Duration(seconds: 1), () {
          _checkDriveStatusAndSync();
        });
      } else {
        if (kDebugMode) {
          print('RecordingController: Firebase user logged out');
        }
        authManager.isDriveSignedIn.value = false;
        authManager.userEmail.value = null;
        authManager.allowToShareAudio.value = false;
        syncManager.loadRecordings();
      }
    });
  }

  Future<void> _loadInitialData() async {
    try {
      // Check Drive authentication and load recordings
      final driveUser = await authManager.checkDriveAuthentication();
      if (driveUser != null) {
        await authManager.validateDriveUser(driveUser);
        // Sync recordings from Drive after validation
        if (authManager.isDriveSignedIn.value) {
          await syncManager.syncFromDrive();
        }
      } else {
        await syncManager.loadRecordings();
      }

      // Load public recordings in background
      Future.microtask(() {
        publishingManager.refreshPublicRecordings();
      });
    } catch (e) {
      if (kDebugMode) {
        print('RecordingController: Error loading initial data: $e');
      }
    }
  }

  Future<void> _checkDriveStatusAndSync() async {
    try {
      final currentUser = await authManager.checkDriveAuthentication();
      if (currentUser != null) {
        await authManager.validateDriveUser(currentUser);
        // Sync recordings from Drive after validation
        if (authManager.isDriveSignedIn.value) {
          await syncManager.syncFromDrive();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('RecordingController: Drive status check failed: $e');
      }
    }
  }

  @override
  void onClose() {
    stateManager.onClose();
    syncManager.onClose();
    super.onClose();
  }

  // ============================================================
  // Delegated Methods - Auth Manager
  // ============================================================

  Future<void> setGuestName(String name) => authManager.setGuestName(name);
  Future<void> signInToDrive() => authManager.signInToDrive();
  Future<void> signOutFromDrive() => authManager.signOutFromDrive();
  Future<void> fetchStorageQuota() => authManager.fetchStorageQuota();

  // ============================================================
  // Delegated Methods - Sync Manager
  // ============================================================

  Future<void> refreshRecordings() => syncManager.refreshRecordings();
  Future<void> syncFromDrive({bool force = false}) =>
      syncManager.syncFromDrive(force: force);

  // Call this when recording page becomes visible
  void onPageVisible() {
    if (kDebugMode) {
      print(
          'RecordingController: Page became visible, refreshing recordings...');
    }
    Future.delayed(const Duration(milliseconds: 200), () {
      syncManager.loadRecordings();
    });
  }

  // ============================================================
  // Delegated Methods - Operations Manager
  // ============================================================

  Future<void> startRecording(String hymnId) =>
      operationsManager.startRecording(hymnId);
  Future<UserRecording?> stopRecording(String hymnId, String title) =>
      operationsManager.stopRecording(hymnId, title);
  Future<void> pauseRecording() => operationsManager.pauseRecording();
  Future<void> resumeRecording() => operationsManager.resumeRecording();
  Future<void> startStandaloneRecording() =>
      operationsManager.startStandaloneRecording();
  Future<UserRecording?> stopStandaloneRecording(String title) =>
      operationsManager.stopStandaloneRecording(title);
  Future<void> updateRecording(UserRecording recording) =>
      operationsManager.updateRecording(recording);
  Future<void> deleteRecording(UserRecording recording) =>
      operationsManager.deleteRecording(recording);
  Future<void> deleteRecordingPermanentlyDirect(UserRecording recording) =>
      operationsManager.deleteRecordingPermanentlyDirect(recording);
  Future<void> renameRecording(UserRecording recording, String newTitle) =>
      operationsManager.renameRecording(recording, newTitle);
  Future<List<UserRecording>> getDeletedRecordings() =>
      operationsManager.getDeletedRecordings();
  Future<void> restoreRecording(UserRecording deletedRecording) =>
      operationsManager.restoreRecording(deletedRecording);
  Future<void> permanentlyDeleteRecording(UserRecording deletedRecording) =>
      operationsManager.permanentlyDeleteRecording(deletedRecording);

  // ============================================================
  // Delegated Methods - Playback Manager
  // ============================================================

  Future<void> playRecording(UserRecording recording) =>
      playbackManager.playRecording(recording);
  Future<void> pausePlayback() => playbackManager.pausePlayback();
  Future<void> seekTo(Duration position) => playbackManager.seekTo(position);
  Future<void> setPlaybackSpeed(double speed) =>
      playbackManager.setPlaybackSpeed(speed);

  void showPlayer(UserRecording recording) {
    playbackManager.showPlayer(
      recording,
      isRecording: isRecording.value,
      onStopRecording: () async {
        await stopRecording(currentHymnId.value, currentHymnTitle.value);
      },
    );
  }

  void hidePlayer() => playbackManager.hidePlayer();
  void minimizePlayer() => playbackManager.minimizePlayer();
  void restorePlayer() => playbackManager.restorePlayer();
  bool shouldShowPlayerOverlay() => playbackManager.shouldShowPlayerOverlay();

  // ============================================================
  // Delegated Methods - Publishing Manager
  // ============================================================

  Future<List<UserRecording>> loadPublicRecordings({String? hymnId}) =>
      publishingManager.loadPublicRecordings(hymnId: hymnId);
  Future<void> refreshPublicRecordings({String? hymnId}) =>
      publishingManager.refreshPublicRecordings(hymnId: hymnId);
  Future<PublishRecordingResult> makeRecordingPublic(UserRecording recording,
          {String? customTitle}) =>
      publishingManager.makeRecordingPublic(recording,
          customTitle: customTitle);
  Future<void> publishRecording(UserRecording recording) =>
      publishingManager.publishRecording(recording);

  // ============================================================
  // Delegated Methods - File Manager
  // ============================================================

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

  // ============================================================
  // Delegated Methods - State Manager (Overlay)
  // ============================================================

  void showOverlay(String hymnId, String hymnTitle) =>
      stateManager.showOverlay(hymnId, hymnTitle);
  void minimizeOverlay() => stateManager.minimizeOverlay();
  void restoreOverlay() => stateManager.restoreOverlay();
  void hideOverlay() => stateManager.hideOverlay();
  bool shouldShowOverlay() => stateManager.shouldShowOverlay();
}
