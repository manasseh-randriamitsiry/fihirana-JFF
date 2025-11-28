import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_controller.dart';
import 'package:uuid/uuid.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import '../models/user_recording.dart';
import '../services/user_recording_service.dart';
import '../services/google_drive_service.dart';
import '../services/public_recording_service.dart';
import '../services/deleted_recording_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hymn.dart';
import '../services/audio_service.dart';
import 'package:fihirana/services/local_audio_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import '../widgets/player/compact_audio_player_widget.dart';
import '../l10n/app_localizations.dart';
import '../services/security_service.dart';

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

class RecordingController extends GetxController {
final UserRecordingService _recordingService = UserRecordingService();
  late final GoogleDriveService _driveService;
  final PublicRecordingService _publicService = PublicRecordingService();
  final DeletedRecordingService _deletedService = DeletedRecordingService();
  final _uuid = const Uuid();

  // Recording state
  final RxBool isRecording = false.obs;
  final RxBool isPaused = false.obs;
  final RxInt recordDuration = 0.obs;
  Timer? _timer;

  // Data
  final RxList<UserRecording> recordings = <UserRecording>[].obs;
  final RxList<UserRecording> publicRecordings = <UserRecording>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isUploading = false.obs;

  // Timer for periodic refresh
  Timer? _periodicRefreshTimer;

  // Drive state
  final RxBool isDriveSignedIn = false.obs;
  final Rxn<String> userEmail = Rxn<String>();
  final RxString guestName = ''.obs;

  // Upload state tracking
  final RxSet<String> uploadingRecordingIds = <String>{}.obs;
  final RxMap<String, String> uploadErrors = <String, String>{}.obs;

  // Overlay state management
  final RxBool isOverlayMinimized = false.obs;
  final RxString currentHymnId = ''.obs;
  final RxString currentHymnTitle = ''.obs;
  final RxBool overlayVisible = false.obs;

  // Audio sharing permission
  final RxBool allowToShareAudio = false.obs;

@override
  void onInit() {
    super.onInit();

    // Initialize critical services first for fast response
    _initializeDriveService();
    _initServices();

    // Defer non-critical operations to avoid blocking UI
    Future.microtask(() async {
      _loadGuestName();
      _loadShareAudioPreference();
      _autoRefreshRecordings();
      refreshPublicRecordings();
      _startPeriodicRefresh();
      await _deletedService.initialize();
    });
  }

  // Separate method to initialize Drive service - can be called multiple times
  void _initializeDriveService() {
    try {
      final authController = Get.find<AuthController>();
      _driveService = authController.driveService;
      if (kDebugMode) {
        print(
            'RecordingController: Drive service initialized from AuthController');
      }
    } catch (e) {
      if (kDebugMode) {
        print('RecordingController: Error initializing Drive service: $e');
      }
    }
  }

  Future<void> _loadGuestName() async {
    final prefs = await SharedPreferences.getInstance();
    guestName.value = prefs.getString('guest_name') ?? '';
  }

  Future<void> _loadShareAudioPreference() async {
    final prefs = await SharedPreferences.getInstance();
    allowToShareAudio.value = prefs.getBool('allowToShareAudio') ?? false;
  }

  Future<void> _setShareAudioPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('allowToShareAudio', value);
    allowToShareAudio.value = value;
  }

  Future<void> setGuestName(String name) async {
    guestName.value = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('guest_name', name);
  }

  // Method to manually refresh recordings
  Future<void> refreshRecordings() async {
    try {
      if (kDebugMode) {
        print('RecordingController: Manually refreshing recordings...');
      }
      await _recordingService.loadRecordings();

      // Fix recordings with unknown hymnId
      await _fixUnknownHymnIds();

      // Clean up ghost recordings
      await _cleanupGhostRecordings();
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing recordings: $e');
      }
    }
  }

  // Clean up ghost recordings (0 duration, no file, but marked as uploaded)
  Future<void> _cleanupGhostRecordings() async {
    try {
      final ghostsToRemove = <UserRecording>[];

      for (final recording in recordings) {
        // Check if this is a ghost recording:
        // 1. Duration is 0
        // 2. No local file
        // 3. Has Drive file ID
        // 4. HymnId is 'unknown' (indicating it couldn't be parsed properly)
        if (recording.durationSeconds == 0 &&
            recording.filePath.isEmpty &&
            recording.driveFileId != null &&
            recording.hymnId == 'unknown') {
          // This is likely a ghost recording from Drive sync that couldn't be properly parsed
          // These recordings serve no purpose since they have no audio and no identifiable hymn
          ghostsToRemove.add(recording);
          if (kDebugMode) {
            print(
                'Found ghost recording to remove: ${recording.title} (ID: ${recording.id})');
          }
        }
      }

      // Remove ghost recordings
      for (final ghost in ghostsToRemove) {
        await _recordingService.deleteRecording(ghost.id);
        if (kDebugMode) {
          print('Removed ghost recording: ${ghost.title}');
        }
      }

      if (ghostsToRemove.isNotEmpty) {
        await _recordingService.loadRecordings(); // Refresh the list
        if (kDebugMode) {
          print('Cleaned up ${ghostsToRemove.length} ghost recordings');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cleaning up ghost recordings: $e');
      }
    }
  }

  // Fix recordings with unknown hymnId by extracting from filename
  Future<void> _fixUnknownHymnIds() async {
    try {
      bool needsUpdate = false;
      final updatedRecordings = <UserRecording>[];

      for (final recording in recordings) {
        if (recording.hymnId == 'unknown') {
          String newHymnId = 'unknown';

          // Try to extract from title or filename
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
                  'Fixed hymnId for recording "${recording.title}": ${recording.hymnId} -> $newHymnId');
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
              'Updated ${updatedRecordings.length} recordings with corrected hymnId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fixing unknown hymnIds: $e');
      }
    }
  }

  Future<List<UserRecording>> loadPublicRecordings({String? hymnId}) async {
    try {
      return await _publicService.getPublicRecordings(hymnId: hymnId);
    } catch (e) {
      if (kDebugMode) {
        print('RecordingController: Load public recordings error: $e');
      }
      return [];
    }
  }

  Future<void> refreshPublicRecordings({String? hymnId}) async {
    try {
      final recordings =
          await _publicService.getPublicRecordings(hymnId: hymnId);
      publicRecordings.value = recordings;
      if (kDebugMode) {
        print(
            'RecordingController: Loaded ${recordings.length} public recordings');
      }
    } catch (e) {
      if (kDebugMode) {
        print('RecordingController: Refresh public recordings error: $e');
      }
    }
  }

  // Auto-refresh recordings when page is accessed
  Future<void> _autoRefreshRecordings() async {
    try {
      if (kDebugMode) {
        print('RecordingController: Auto-refreshing recordings...');
      }

      // Small delay to ensure UI is ready
      await Future.delayed(const Duration(milliseconds: 100));
      await _recordingService.loadRecordings();

      if (kDebugMode) {
        print('RecordingController: Auto-refresh complete');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error auto-refreshing recordings: $e');
      }
    }
  }

  // Periodic refresh to keep recordings in sync
  void _startPeriodicRefresh() {
    // Refresh every 30 seconds
    _periodicRefreshTimer =
        Timer.periodic(const Duration(seconds: 30), (timer) {
      if (kDebugMode) {
        print('RecordingController: Periodic refresh triggered');
      }

      // Only refresh if not already loading to avoid conflicts
      if (!isLoading.value) {
        _recordingService.loadRecordings();
      }

      // Check for silent sign-in every 2 minutes (every 4 ticks)
      if (!isDriveSignedIn.value && timer.tick % 4 == 0) {
        _checkForSilentSignIn();
      }

      // Also sync from Drive if signed in (every 5 minutes to avoid API limits)
      if (isDriveSignedIn.value && timer.tick % 10 == 0 && !isLoading.value) {
        syncFromDrive();
      }
    });
  }

  // Check for silent sign-in periodically
  Future<void> _checkForSilentSignIn() async {
    try {
      final currentUser = await _driveService.signInSilently();
      if (currentUser != null) {
        if (kDebugMode) {
          print(
              'RecordingController: Periodic check found Drive account: ${currentUser.email}');
        }
        await _validateDriveUser(currentUser);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Periodic silent sign-in check failed: $e');
      }
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    // _audioPlayer.dispose(); // No longer needed
    _periodicRefreshTimer?.cancel(); // Stop periodic refresh
    super.onClose();
  }

  // Call this when recording page becomes visible
  void onPageVisible() {
    if (kDebugMode) {
      print(
          'RecordingController: Page became visible, refreshing recordings...');
    }

    // Ensure Drive service is properly initialized
    _initializeDriveService();

    // Check Drive status and sync if needed
    _checkDriveStatusAndSync();

    // Auto-refresh with delay to avoid conflicts
    Future.delayed(const Duration(milliseconds: 200), () {
      _autoRefreshRecordings();
    });
  }

  Future<void> _checkDriveStatusAndSync() async {
    try {
      final currentUser = _driveService.currentUser;
      if (kDebugMode) {
        print('RecordingController: Checking Drive service status...');
        print('RecordingController: Current user: ${currentUser?.email}');
      }

      if (currentUser != null) {
        await _validateDriveUser(currentUser);
      } else {
        if (kDebugMode) {
          print('RecordingController: No existing Google Drive account found');
        }
      }
    } catch (e) {
      // Drive status check failed
      if (kDebugMode) {
        print('Drive status check failed: $e');
      }
    }
  }

  Future<void> _initServices() async {
    try {
      if (kDebugMode) {
        print('RecordingController: Starting initialization...');
      }

      await _recordingService.initialize();

      // Bind to stream BEFORE checking Drive status
      recordings.bindStream(_recordingService.recordingsStream);

      if (kDebugMode) {
        print('RecordingController: Service initialized, stream bound');
      }

      // Listen to stream for debugging
      recordings.listen((recordingsList) {
        if (kDebugMode) {
          print(
              'RecordingController: Stream updated with ${recordingsList.length} recordings');
        }
      });

      // Small delay to ensure stream is ready
      await Future.delayed(const Duration(milliseconds: 200));

      // Check if Drive service is already signed in from AuthController
      try {
        final currentUser = _driveService.currentUser;
        if (kDebugMode) {
          print('RecordingController: Checking Drive service status...');
          print('RecordingController: Current user: ${currentUser?.email}');
        }

        if (currentUser != null) {
          await _validateDriveUser(currentUser);
        } else {
          if (kDebugMode) {
            print(
                'RecordingController: No existing Google Drive account found');
          }
        }
      } catch (e) {
        // Drive status check failed
        if (kDebugMode) {
          print('Drive status check failed: $e');
        }
      }

      if (kDebugMode) {
        print('RecordingController: Initialization complete');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing services: $e');
      }
    }
  }

  // Helper to validate Drive user and set permissions
  Future<void> _validateDriveUser(GoogleSignInAccount user) async {
    try {
      // Check if email is banned
      final securityService = SecurityService.instance;
      final isEmailBanned = await securityService.isEmailBlocked(user.email);

      if (isEmailBanned) {
        if (kDebugMode) {
          print(
              'RecordingController: Email ${user.email} is banned, denying access');
        }

        // Sign out immediately and deny access
        await _driveService.signOut();
        isDriveSignedIn.value = false;
        userEmail.value = null;
        await _setShareAudioPreference(false);

        // Only show snackbar if we're in a visible context (not background init)
        if (Get.context != null) {
          Get.snackbar(
            'Access Denied',
            'This email is not allowed to share audio content.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        }
        return;
      }

      // User is valid
      isDriveSignedIn.value = true;
      userEmail.value = user.email;

      // Allow sharing for non-banned emails
      await _setShareAudioPreference(true);

      if (kDebugMode) {
        print('RecordingController: Validated Drive account: ${user.email}');
        print('RecordingController: Audio sharing enabled');
      }

      // Auto-sync recordings from Drive
      await syncFromDrive();
    } catch (e) {
      if (kDebugMode) {
        print('Error validating Drive user: $e');
      }
    }
  }

  // void _setupAudioPlayerListeners() {
  //   _audioPlayer.playerStateStream.listen((state) {
  //     isPlaying.value = state.playing;
  //     if (state.processingState == ProcessingState.completed) {
  //       isPlaying.value = false;
  //       currentPlayingId.value = '';
  //       currentPosition.value = Duration.zero;
  //     }
  //   });
  //
  //   _audioPlayer.positionStream.listen((position) {
  //     currentPosition.value = position;
  //   });
  //
  //   _audioPlayer.durationStream.listen((duration) {
  //     totalDuration.value = duration ?? Duration.zero;
  //   });
  // }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      recordDuration.value++;
    });
  }

  // Recording Actions
  Future<void> startRecording(String hymnId) async {
    // Security check first
    if (!await _checkUserCanRecord()) {
      return;
    }

    await _recordingService.startRecording(hymnId);
    isRecording.value = true;
    isPaused.value = false;
    recordDuration.value = 0;
    _startTimer();

    // Show overlay when recording starts (only for hymn recordings)
    if (hymnId != 'unknown') {
      showOverlay(
          hymnId, 'Hymn $hymnId'); // You might want to pass actual title
    }
  }

  Future<UserRecording?> stopRecording(String hymnId, String title) async {
    final filePath = await _recordingService.stopRecording();
    final duration = recordDuration.value; // Save duration before resetting

    isRecording.value = false;
    isPaused.value = false;
    recordDuration.value = 0; // Reset timer display
    _timer?.cancel();

    if (filePath != null) {
      // Get current user info
      String? currentUserId;
      String? currentUserEmail;
      String? currentUserPhotoUrl;
      String? currentUserName = guestName.value;

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        currentUserId = currentUser.uid;
        currentUserEmail = currentUser.email;
        currentUserPhotoUrl = currentUser.photoURL;
        currentUserName = currentUser.displayName ?? currentUserName;
      } else if (isDriveSignedIn.value && userEmail.value != null) {
        // Fallback to Drive user info if not signed in to Firebase but signed in to Drive
        final driveUser = _driveService.currentUser;
        if (driveUser != null) {
          currentUserId = driveUser.id;
          currentUserEmail = driveUser.email;
          currentUserPhotoUrl = driveUser.photoUrl;
          currentUserName = driveUser.displayName ?? currentUserName;
        }
      }

      final recording = await _recordingService.saveRecording(
        filePath: filePath,
        hymnId: hymnId,
        title: title,
        durationSeconds: duration, // Use saved duration
        userId: currentUserId,
        userEmail: currentUserEmail,
        userPhotoUrl: currentUserPhotoUrl,
        userName: currentUserName,
      );

      // Update overlay title with actual title
      currentHymnTitle.value = title;

      return recording;
    }
    return null;
  }

  Future<void> pauseRecording() async {
    await _recordingService.pauseRecording();
    isPaused.value = true;
    _timer?.cancel();
  }

  Future<void> resumeRecording() async {
    await _recordingService.resumeRecording();
    isPaused.value = false;
    _startTimer();
  }

  // Standalone recording methods for non-hymn recordings
  Future<void> startStandaloneRecording() async {
    // Security check first
    if (!await _checkUserCanRecord()) {
      return;
    }

    await _recordingService.startRecording('unknown');
    isRecording.value = true;
    isPaused.value = false;
    recordDuration.value = 0;
    _startTimer();
  }

  Future<UserRecording?> stopStandaloneRecording(String title) async {
    final filePath = await _recordingService.stopRecording();
    isRecording.value = false;
    isPaused.value = false;
    _timer?.cancel();

    if (filePath != null) {
      // Get current user info
      String? currentUserId;
      String? currentUserEmail;
      String? currentUserPhotoUrl;
      String? currentUserName = guestName.value;

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        currentUserId = currentUser.uid;
        currentUserEmail = currentUser.email;
        currentUserPhotoUrl = currentUser.photoURL;
        currentUserName = currentUser.displayName ?? currentUserName;
      } else if (isDriveSignedIn.value && userEmail.value != null) {
        // Fallback to Drive user info if not signed in to Firebase but signed in to Drive
        final driveUser = _driveService.currentUser;
        if (driveUser != null) {
          currentUserId = driveUser.id;
          currentUserEmail = driveUser.email;
          currentUserPhotoUrl = driveUser.photoUrl;
          currentUserName = driveUser.displayName ?? currentUserName;
        }
      }

      final recording = await _recordingService.saveRecording(
        filePath: filePath,
        hymnId: 'unknown',
        title: title,
        durationSeconds: recordDuration.value,
        userId: currentUserId,
        userEmail: currentUserEmail,
        userPhotoUrl: currentUserPhotoUrl,
        userName: currentUserName,
      );

      return recording;
    }
    return null;
  }

  // Playback Actions
  Future<void> playRecording(UserRecording recording) async {
    try {
      // Use AudioService to play the recording
      await AudioService.instance.playRecording(recording);
    } catch (e) {
      Get.snackbar('Error', 'Failed to play recording: $e');
    }
  }

  Future<void> pausePlayback() async {
    await AudioService.instance.pause();
  }

  Future<void> seekTo(Duration position) async {
    await AudioService.instance.seekTo(position);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    // playbackSpeed.value = speed;
    await AudioService.instance.player.setSpeed(speed);
  }

// Management Actions
  Future<void> deleteRecording(UserRecording recording) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final authController = Get.find<AuthController>();
      
      // Check if current user is the owner
      final isOwner = recording.userId == currentUser?.uid || recording.userEmail == currentUser?.email;
      final isAdmin = authController.isAdmin || authController.isSuperAdmin;
      
      if (isOwner) {
        // Owner deletion: permanent deletion (no trash)
        await _deleteRecordingPermanently(recording, currentUser);
      } else if (isAdmin) {
        // Admin deletion: move to trash
        await _moveRecordingToTrash(recording);
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

  Future<void> _deleteRecordingPermanently(UserRecording recording, User? currentUser) async {
    try {
      // Delete from local storage
      await _recordingService.deleteRecording(recording.id);
      
      // Delete from Google Drive if exists
      if (recording.driveFileId != null) {
        try {
          await _driveService.deleteFile(recording.driveFileId!);
        } catch (e) {
          // Log error but don't fail the deletion
          if (kDebugMode) {
            print('Failed to delete from Google Drive: $e');
          }
        }
      }
      
      // Unpublish from public recordings if it was public
      if (recording.isPublic) {
        try {
          await _publicService.unpublishRecording(recording.id);
        } catch (e) {
          if (kDebugMode) {
            print('Failed to unpublish recording: $e');
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

  Future<void> _moveRecordingToTrash(UserRecording recording) async {
    try {
      // Save to deleted recordings before deleting
      await _deletedService.saveDeletedRecording(recording);
      
      // Delete from local storage
      await _recordingService.deleteRecording(recording.id);
      
      // Unpublish from public recordings if it was public
      if (recording.isPublic) {
        try {
          await _publicService.unpublishRecording(recording.id);
        } catch (e) {
          if (kDebugMode) {
            print('Failed to unpublish recording: $e');
          }
        }
      }
      
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

  // Storage quota state
  final Rx<drive.AboutStorageQuota?> storageQuota =
      Rx<drive.AboutStorageQuota?>(null);

  Future<void> fetchStorageQuota() async {
    if (!isDriveSignedIn.value) return;

    try {
      final quota = await _driveService.getStorageQuota();
      storageQuota.value = quota;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching storage quota: $e');
      }
    }
  }

  Future<void> updateRecording(UserRecording recording) async {
    await _recordingService.updateRecording(recording);
  }

  Future<PublishRecordingResult> makeRecordingPublic(UserRecording recording, {String? customTitle}) async {
// 1. Check if user can share
    if (!allowToShareAudio.value) {
      Get.snackbar(
        'Access Denied',
        'You are not allowed to share audio content.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return PublishRecordingResult.accessDenied;
    }

// 2. Ensure signed in to Drive
    if (!isDriveSignedIn.value) {
      await signInToDrive();
      if (!isDriveSignedIn.value) {
        Get.snackbar(
          'Sign In Required',
          'You must be signed in to Google Drive to share recordings.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return PublishRecordingResult.signInRequired;
      }
    }

// Check storage quota
    await fetchStorageQuota();
    final quota = storageQuota.value;
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
      isUploading.value = true;
      UserRecording recordingToPublish = recording;
      
      // Use custom title if provided
      if (customTitle != null && customTitle.isNotEmpty) {
        recordingToPublish = recording.copyWith(title: customTitle);
      }

      // 3. Upload to Drive if not already uploaded
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

        final fileId = await _driveService.uploadFile(
          file,
          '${recording.title}.m4a',
          description: 'Hymn: ${recording.hymnId}',
        );

        if (fileId != null) {
          final webLink = await _driveService.getWebViewLink(fileId);
          recordingToPublish = recording.copyWith(
            driveFileId: fileId,
            driveWebLink: webLink,
          );
          await _recordingService.updateRecording(recordingToPublish);

          // Refresh quota after upload
          fetchStorageQuota();
        } else {
          return PublishRecordingResult.uploadFailed;
        }
      }

      // 4. Check for duplicate title before publishing (only after Drive upload succeeds)
      final titleExists = await _publicService.titleExistsForHymn(
        recordingToPublish.hymnId, 
        recordingToPublish.title,
      );
      if (titleExists) {
        return PublishRecordingResult.duplicateTitle;
      }

      // 5. Publish to Firestore
      final success = await _publicService.publishRecording(recordingToPublish);

      if (success) {
        // 5. Update local state
        final updated = recordingToPublish.copyWith(isPublic: true);
        await _recordingService.updateRecording(updated);

        // Refresh lists
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
      isUploading.value = false;
}

  
}

  // Helper method to check if a recording is currently uploading
  bool isUploadingRecording(String recordingId) {
    return uploadingRecordingIds.contains(recordingId);
  }

  // Helper method to get upload error for a recording
  String? getUploadError(String recordingId) {
    return uploadErrors[recordingId];
  }

  // Security check to prevent banned users from recording (but allow guests)
  Future<bool> _checkUserCanRecord() async {
    final SecurityService securityService = SecurityService.instance;

    // Check if user is authenticated via Firebase
    final isFirebaseAuthenticated = FirebaseAuth.instance.currentUser != null;

    // Check if user is authenticated via Google Drive
    final isGoogleDriveAuthenticated = _driveService.currentUser != null;

    // Allow all users (including guests) to record - no authentication required for recording

    // Check Firebase user security if authenticated via Firebase
    if (isFirebaseAuthenticated) {
      await securityService.checkUserSecurity();
      if (securityService.isUserBlocked) {
        if (kDebugMode) {
          print('🚫 Blocked Firebase user attempted to record/publish');
        }
        Get.snackbar(
          'Access Denied',
          'Your account has been restricted. Recording and publishing features are not available.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
        return false;
      }
    }

    // Check Google Drive user email if authenticated via Google Drive
    if (isGoogleDriveAuthenticated) {
      final googleUserEmail = _driveService.currentUser?.email;
      if (googleUserEmail != null) {
        final isEmailBlocked =
            await securityService.isEmailBlocked(googleUserEmail);
        if (isEmailBlocked) {
          if (kDebugMode) {
            print(
                '🚫 Blocked Google Drive user attempted to record/publish: $googleUserEmail');
          }
          Get.snackbar(
            'Access Denied',
            'Your account has been restricted. Recording and publishing features are not available.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 5),
          );
          return false;
        }
      }
    }

    // All users (including guests) are allowed to record
    return true;
  }

  // Method to retry upload for a failed recording
  Future<void> retryUpload(UserRecording recording) async {
    uploadErrors.remove(recording.id);
    await uploadToDrive(recording);
  }

  // Sync recordings from Google Drive
  Future<void> syncFromDrive() async {
    if (kDebugMode) {
      print('RecordingController: syncFromDrive() called');
      print(
          'RecordingController: isDriveSignedIn.value = ${isDriveSignedIn.value}');
    }

    if (!isDriveSignedIn.value) {
      if (kDebugMode) {
        print('Cannot sync from Drive: Not signed in');
      }
      return;
    }

    // Prevent concurrent syncs
    if (isLoading.value) {
      if (kDebugMode) {
        print('Sync already in progress, skipping');
      }
      return;
    }

    try {
      isLoading.value = true;
      final driveFiles = await _driveService.listRecordings();

      if (kDebugMode) {
        print('Found ${driveFiles.length} files in Drive');
      }

      // Create a map of existing recordings by drive file ID for quick lookup
      final existingByDriveId = <String, UserRecording>{};
      for (final recording in recordings) {
        if (recording.driveFileId != null) {
          existingByDriveId[recording.driveFileId!] = recording;
        }
      }

      // Check for files in Drive that aren't in local recordings
      for (final driveFile in driveFiles) {
        if (!existingByDriveId.containsKey(driveFile.id!)) {
          // This is a new recording from Drive that's not in local storage
          // Create a local entry for it
          // Parse hymnId more safely from description or filename
          String hymnId = 'unknown';
          if (driveFile.description != null &&
              driveFile.description!.contains('Hymn:')) {
            final parts = driveFile.description!.split('Hymn: ');
            if (parts.length > 1) {
              hymnId = parts.last.trim();
              // Validate hymnId format (should be numeric)
              if (!RegExp(r'^\d+$').hasMatch(hymnId)) {
                hymnId = 'unknown';
              }
            }
          } else {
            // Try to extract hymnId from filename as fallback
            final fileName = (driveFile.name ?? '')
                .replaceAll('.m4a', '')
                .replaceAll('.mp3', '');
            // Look for patterns like "rec_123_" or "Hymn 123" or just numbers
            final numberMatch = RegExp(r'(\d+)').firstMatch(fileName);
            if (numberMatch != null) {
              hymnId = numberMatch.group(1)!;
            }
          }

          // Check if this recording already exists locally by comparing title and creation time
          final fileName = (driveFile.name ?? '')
              .replaceAll('.m4a', '')
              .replaceAll('.mp3', '');
          final driveCreatedTime =
              DateTime.tryParse(driveFile.createdTime?.toString() ?? '') ??
                  DateTime.now();

          final existingLocalRecording = recordings.firstWhereOrNull((r) =>
              r.title == fileName &&
              r.driveFileId == null && // Only match local recordings
              (r.createdAt.difference(driveCreatedTime).inSeconds.abs() <
                  300)); // Within 5 minutes

          if (existingLocalRecording != null) {
            // This is likely the same recording that was just uploaded
            // Update the existing recording instead of creating a duplicate
            final updated = existingLocalRecording.copyWith(
              driveFileId: driveFile.id,
              driveWebLink: driveFile.webViewLink,
            );
            await _recordingService.updateRecording(updated);

            if (kDebugMode) {
              print(
                  'Updated existing recording with Drive info: ${existingLocalRecording.title}');
            }
          } else {
            // Only create recording entry if we can properly identify the hymn
            // This prevents creating ghost recordings for unidentifiable files
            if (hymnId != 'unknown') {
              // Create new recording entry
              final recording = UserRecording(
                id: _uuid.v4(),
                hymnId: hymnId,
                title: fileName,
                filePath: '', // No local file available
                durationSeconds: 0, // Unknown duration
                createdAt: driveCreatedTime,
                isPublic: false,
                tags: [],
                driveFileId: driveFile.id ?? '',
                driveWebLink: driveFile.webViewLink,
              );

              // Use saveDriveRecording to add it directly with Drive info
              await _recordingService.saveDriveRecording(recording);

              if (kDebugMode) {
                print(
                    'Added new recording from Drive: ${recording.title} (Hymn: $hymnId)');
              }
            } else {
              if (kDebugMode) {
                print(
                    'Skipping unidentifiable Drive file: ${driveFile.name} - could not extract hymn ID');
              }
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
            // The Drive file was deleted externally, update local recording
            final updated = recording.copyWith(
              driveFileId: null,
              driveWebLink: null,
            );
            await _recordingService.updateRecording(updated);

            if (kDebugMode) {
              print(
                  'Removed Drive reference for deleted file: ${recording.title}');
            }
          }
        }
      }

      // Refresh recordings to show updated list
      await _recordingService.loadRecordings();

      if (kDebugMode) {
        print('Drive sync completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing from Drive: $e');
      }
      Get.snackbar(
        'Sync Failed',
        'Failed to sync recordings from Drive: ${e.toString()}',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Overlay state management methods
  void showOverlay(String hymnId, String hymnTitle) {
    currentHymnId.value = hymnId;
    currentHymnTitle.value = hymnTitle;
    overlayVisible.value = true;
    isOverlayMinimized.value = false;
  }

  void minimizeOverlay() {
    isOverlayMinimized.value = true;
  }

  void restoreOverlay() {
    isOverlayMinimized.value = false;
  }

  void hideOverlay() {
    overlayVisible.value = false;
    isOverlayMinimized.value = false;
    currentHymnId.value = '';
    currentHymnTitle.value = '';
  }

  bool shouldShowOverlay() {
    return overlayVisible.value;
  }

  void _showStopRecordingDialog(UserRecording recording) {
    final l10n = AppLocalizations.of(Get.context!);
    Get.dialog(
      AlertDialog(
        title: Text(l10n!.recordingInProgressDialog),
        content: Text(l10n.pleaseStopRecordingBeforePlaying),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await stopRecording(currentHymnId.value, currentHymnTitle.value);
              hideOverlay();
              _proceedWithPlayback(recording);
            },
            child: Text(l10n.stopAndPlay),
          ),
        ],
      ),
    );
  }

  void _proceedWithPlayback(UserRecording recording) {
    // Create a hymn object from the recording
    final hymn = Hymn(
      id: recording.id,
      hymnNumber: recording.hymnId,
      title: recording.title,
      verses: [],
      createdAt: recording.createdAt,
      createdBy: 'User',
    );

    // Show compact audio player as modal bottom sheet
    _showCompactAudioPlayer(hymn, recording);

    // Start playing
    playRecording(recording);
  }

  void _showCompactAudioPlayer(Hymn hymn, UserRecording recording) {
    Get.bottomSheet(
      CompactAudioPlayerWidget(
        hymn: hymn,
        playlist: [hymn],
        onClose: () => Get.back(),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
    );
  }

  // Player Overlay state management
  final RxBool isPlayerOverlayVisible = false.obs;
  final RxBool isPlayerMinimized = false.obs;
  final Rxn<UserRecording> currentRecording = Rxn<UserRecording>();

  void showPlayer(UserRecording recording) {
    // If recording is in progress, ask user to stop
    if (isRecording.value) {
      _showStopRecordingDialog(recording);
      return;
    }

    // If overlay is visible, close it automatically
    if (overlayVisible.value) {
      hideOverlay();
    }

    _proceedWithPlayback(recording);
  }

  void hidePlayer() {
    isPlayerOverlayVisible.value = false;
    isPlayerMinimized.value = false;
    currentRecording.value = null;
    pausePlayback();
  }

  void minimizePlayer() {
    isPlayerMinimized.value = true;
  }

  void restorePlayer() {
    isPlayerMinimized.value = false;
  }

  bool shouldShowPlayerOverlay() {
    return isPlayerOverlayVisible.value;
  }

  Future<void> downloadRecording(UserRecording recording) async {
    // Security check first
    if (!await _checkUserCanRecord()) {
      return;
    }

    try {
      // Check if already exists
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

      // Determine target path
      String targetPath = recording.filePath;
      if (targetPath.isEmpty) {
        final localService = LocalAudioService();
        await localService.initialize();
        final stats = await localService.getStorageStats();
        final dir = stats['directory'] as String;
        targetPath = path.join(dir, 'recording_${recording.id}.m4a');
      }

      final driveService = GoogleDriveService();
      if (!driveService.isSignedIn) {
        await driveService.signInSilently();
      }

      if (!driveService.isSignedIn) {
        throw Exception('Not signed in to Drive');
      }

      final file =
          await driveService.downloadFile(recording.driveFileId!, targetPath);

      if (file != null && await file.exists()) {
        // Update recording with new path
        final updatedRecording = recording.copyWith(filePath: file.path);
        await _recordingService.updateRecording(updatedRecording);

        // Update in list
        final index = recordings.indexWhere((r) => r.id == recording.id);
        if (index != -1) {
          recordings[index] = updatedRecording;
        }

        Get.back(); // Close progress snackbar
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
        print('RecordingController: Download error: $e');
      }
      Get.back(); // Close progress snackbar
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
    // Security check first
    if (!await _checkUserCanRecord()) {
      return;
    }

    try {
      String? filePath = recording.filePath;
      bool fileExists = filePath.isNotEmpty && await File(filePath).exists();

      if (!fileExists) {
        // Try to download first
        if (recording.driveFileId != null) {
          Get.snackbar(
            'Preparing Share',
            'Downloading file to share...',
            showProgressIndicator: true,
            snackPosition: SnackPosition.BOTTOM,
          );

          // Determine target path
          String targetPath = recording.filePath;
          if (targetPath.isEmpty) {
            final localService = LocalAudioService();
            await localService.initialize();
            final stats = await localService.getStorageStats();
            final dir = stats['directory'] as String;
            targetPath = path.join(dir, 'recording_${recording.id}.m4a');
          }

          final driveService = GoogleDriveService();
          if (!driveService.isSignedIn) {
            await driveService.signInSilently();
          }

          if (driveService.isSignedIn) {
            final file = await driveService.downloadFile(
                recording.driveFileId!, targetPath);
            if (file != null && await file.exists()) {
              filePath = file.path;

              // Update recording with new path
              final updatedRecording = recording.copyWith(filePath: filePath);
              await _recordingService.updateRecording(updatedRecording);

              // Update in list
              final index = recordings.indexWhere((r) => r.id == recording.id);
              if (index != -1) {
                recordings[index] = updatedRecording;
              }
            }
          }
        }
      }

      if (await File(filePath).exists()) {
        // Share the file
        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'Check out my recording of ${recording.title}',
        );
      } else if (recording.driveWebLink != null) {
        // Fallback to link
        await Share.share(
            'Check out this recording: ${recording.driveWebLink}');
      } else {
        Get.snackbar('Error', 'Could not share recording. File not found.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('RecordingController: Share error: $e');
      }
      Get.snackbar('Error', 'Failed to share recording');
    }
  }

  Future<void> exportRecording(UserRecording recording) async {
    // Security check first
    if (!await _checkUserCanRecord()) {
      return;
    }

    try {
      String? filePath = recording.filePath;

      // Download from Drive if needed
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

          final driveService = GoogleDriveService();
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

      // Use file_picker to let user choose save location
      final fileName = path.basename(filePath);

      // Read file as bytes
      final sourceFile = File(filePath);
      final bytes = await sourceFile.readAsBytes();

      // Let user pick save location with bytes
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Recording',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['m4a'],
        bytes: bytes,
      );

      if (outputPath == null) {
        // User cancelled
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
        print('RecordingController: Export error: $e');
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

  Future<void> signInToDrive() async {
    try {
      final account = await _driveService.signIn();
      if (account != null) {
        await _validateDriveUser(account);
        // Fetch storage quota after sign in
        await fetchStorageQuota();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error signing in to Drive: $e');
      }
      Get.snackbar(
        'Sign In Failed',
        'Failed to sign in to Google Drive: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> signOutFromDrive() async {
    try {
      await _driveService.signOut();
      isDriveSignedIn.value = false;
      userEmail.value = null;
      storageQuota.value = null;

      // Clear Drive info from local recordings
      // Note: We don't delete the local recordings, just unlink them
      /*
      for (final recording in recordings) {
        if (recording.driveFileId != null) {
          final updated = recording.copyWith(
            driveFileId: null,
            driveWebLink: null,
          );
          await _recordingService.updateRecording(updated);
        }
      }
      await _recordingService.loadRecordings();
      */

      Get.snackbar(
        'Signed Out',
        'Signed out from Google Drive',
        backgroundColor: Colors.grey[800],
        colorText: Colors.white,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error signing out from Drive: $e');
      }
    }
  }

  Future<void> uploadToDrive(UserRecording recording) async {
    if (!allowToShareAudio.value) {
      Get.snackbar(
        'Access Denied',
        'You are not allowed to upload audio content.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (!isDriveSignedIn.value) {
      await signInToDrive();
      if (!isDriveSignedIn.value) return;
    }

    // Check storage quota
    await fetchStorageQuota();
    final quota = storageQuota.value;
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
      isUploading.value = true;
      uploadingRecordingIds.add(recording.id);
      uploadErrors.remove(recording.id);

      final file = File(recording.filePath);
      if (!await file.exists()) {
        throw Exception('Recording file not found');
      }

      final fileId = await _driveService.uploadFile(
        file,
        '${recording.title}.m4a',
        description: 'Hymn: ${recording.hymnId}',
      );

      if (fileId != null) {
        final webLink = await _driveService.getWebViewLink(fileId);
        final updatedRecording = recording.copyWith(
          driveFileId: fileId,
          driveWebLink: webLink,
        );
        await _recordingService.updateRecording(updatedRecording);

        // Update in list
        final index = recordings.indexWhere((r) => r.id == recording.id);
        if (index != -1) {
          recordings[index] = updatedRecording;
        }

        // Refresh quota after upload
        fetchStorageQuota();

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
      isUploading.value = false;
      uploadingRecordingIds.remove(recording.id);
    }
  }

Future<void> renameRecording(UserRecording recording, String newTitle) async {
    try {
      final updated = recording.copyWith(title: newTitle);
      await _recordingService.updateRecording(updated);

      // Update in list
      final index = recordings.indexWhere((r) => r.id == recording.id);
      if (index != -1) {
        recordings[index] = updated;
      }

      // If uploaded to Drive, rename there too (optional, but good for consistency)
      // This would require a renameFile method in GoogleDriveService
    } catch (e) {
      Get.snackbar('Error', 'Failed to rename recording: $e');
    }
  }

  // Deleted recordings management
  Future<List<UserRecording>> getDeletedRecordings() async {
    return await _deletedService.getDeletedRecordings();
  }

  Future<void> restoreRecording(UserRecording deletedRecording) async {
    try {
      // Create a new recording with original data but new ID
      final restoredRecording = UserRecording(
        id: _uuid.v4(),
        hymnId: deletedRecording.hymnId,
        title: deletedRecording.title,
        filePath: deletedRecording.filePath,
        durationSeconds: deletedRecording.durationSeconds,
        createdAt: DateTime.now(), // Use current time for restored recording
        isPublic: false, // Always restore as private
        driveFileId: deletedRecording.driveFileId,
        driveWebLink: deletedRecording.driveWebLink,
        userName: deletedRecording.userName,
        userId: deletedRecording.userId,
        userEmail: deletedRecording.userEmail,
        userPhotoUrl: deletedRecording.userPhotoUrl,
        tags: deletedRecording.tags,
      );

      // Save to recordings
      await _recordingService.saveRecording(
        filePath: restoredRecording.filePath,
        hymnId: restoredRecording.hymnId,
        title: restoredRecording.title,
        durationSeconds: restoredRecording.durationSeconds,
        userId: restoredRecording.userId,
        userEmail: restoredRecording.userEmail,
        userPhotoUrl: restoredRecording.userPhotoUrl,
        userName: restoredRecording.userName,
      );

      // Remove from deleted recordings
      await _deletedService.restoreRecording(deletedRecording.id);

      // Refresh recordings
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

  Future<void> permanentlyDeleteRecording(UserRecording deletedRecording) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      
      // Only delete from Google Drive if the current user is the owner
      // Admins can't delete users' Drive files, only the link
      if (deletedRecording.driveFileId != null && 
          (deletedRecording.userId == currentUser?.uid || deletedRecording.userEmail == currentUser?.email)) {
        try {
          await _driveService.deleteFile(deletedRecording.driveFileId!);
        } catch (e) {
          if (kDebugMode) {
            print('Failed to delete from Google Drive: $e');
          }
        }
      }

      // Remove from deleted recordings permanently
      await _deletedService.permanentlyDeleteRecording(deletedRecording.id);

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

  Future<void> publishRecording(UserRecording recording) async {
    // Security check first
    if (!await _checkUserCanRecord()) {
      return;
    }

    try {
      Get.snackbar(
        'Publishing',
        'Making recording public...',
        showProgressIndicator: true,
        snackPosition: SnackPosition.BOTTOM,
      );

      // Get user name from preferences or auth
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('guest_name') ?? guestName.value;

      // Upload to public folder if not already on Drive
      String? driveFileId = recording.driveFileId;
      String? publicLink;

      if (driveFileId == null && recording.filePath.isNotEmpty) {
        // Upload to Drive public folder
        final file = File(recording.filePath);
        if (await file.exists()) {
          driveFileId = await _driveService.uploadFile(
            file,
            recording.title,
            isPublic: true,
          );
        }
      } else if (driveFileId != null) {
        // Set existing file to public
        await _driveService.setFilePublic(driveFileId);
      }

      if (driveFileId != null) {
        publicLink = await _driveService.getPublicLink(driveFileId);
      }

      if (driveFileId == null || publicLink == null) {
        throw Exception('Failed to upload or get public link');
      }

// Update recording
      var updatedRecording = recording.copyWith(
        isPublic: true,
        driveFileId: driveFileId,
        publicLink: publicLink,
        userName: userName,
      );

      // Check for duplicate title before publishing (allow multiple attempts)
      // Only check after Drive upload succeeds
      UserRecording currentRecording = updatedRecording;
      bool titleExists = await _publicService.titleExistsForHymn(
        currentRecording.hymnId, 
        currentRecording.title,
      );
      
      while (titleExists) {
        Get.back(); // Close progress
        
        // Show dialog to allow title editing
        final newTitle = await _showDuplicateTitleDialog(currentRecording);
        if (newTitle == null) {
          // User cancelled
          return;
        }
        
        // Update recording with new title
        currentRecording = currentRecording.copyWith(title: newTitle);
        
        // Show progress again
        Get.snackbar(
          'Publishing',
          'Making recording public...',
          showProgressIndicator: true,
          snackPosition: SnackPosition.BOTTOM,
        );
        
        // Check if new title still exists
        titleExists = await _publicService.titleExistsForHymn(
          currentRecording.hymnId, 
          currentRecording.title,
        );
      }
      
      // Use the final recording (with potentially updated title)
      updatedRecording = currentRecording;

      // Save to Firestore
      final success = await _publicService.publishRecording(updatedRecording);
      if (!success) {
        throw Exception('Failed to publish to Firestore');
      }

      // Update local recording
      await _recordingService.updateRecording(updatedRecording);
      final index = recordings.indexWhere((r) => r.id == recording.id);
      if (index != -1) {
        recordings[index] = updatedRecording;
      }

      // Refresh public recordings list
      await refreshPublicRecordings();

      Get.back(); // Close progress
      Get.snackbar(
        'Success',
        'Recording is now public!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.1),
        colorText: Colors.green,
      );
    } catch (e) {
      if (kDebugMode) {
        print('RecordingController: Publish error: $e');
      }
      Get.back(); // Close progress
      Get.snackbar(
        'Error',
        'Failed to publish recording: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    }
  }

  Future<void> unpublishRecording(UserRecording recording) async {
    try {
      Get.snackbar(
        'Unpublishing',
        'Making recording private...',
        showProgressIndicator: true,
        snackPosition: SnackPosition.BOTTOM,
      );

      // Remove from Firestore
      await _publicService.unpublishRecording(recording.id);

      // Update local recording
      final updatedRecording = recording.copyWith(
        isPublic: false,
        publicLink: null,
      );

      await _recordingService.updateRecording(updatedRecording);
      final index = recordings.indexWhere((r) => r.id == recording.id);
      if (index != -1) {
        recordings[index] = updatedRecording;
      }

      // Refresh public recordings list
      await refreshPublicRecordings();

      Get.back(); // Close progress
      Get.snackbar(
        'Success',
        'Recording is now private',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.1),
        colorText: Colors.green,
      );
    } catch (e) {
      if (kDebugMode) {
        print('RecordingController: Unpublish error: $e');
      }
      Get.back(); // Close progress
      Get.snackbar(
        'Error',
        'Failed to unpublish recording',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    }
  }

  // Method to re-upload problematic Drive files
  Future<void> reuploadToDrive(UserRecording recording) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    // Check if user is owner or admin
    final isOwner = recording.userId == currentUser?.uid || recording.userEmail == currentUser?.email;
    final authController = Get.find<AuthController>();
    final isAdmin = authController.isAdmin || authController.isSuperAdmin;
    
    if (!isOwner && !isAdmin) {
      Get.snackbar(
        'Access Denied',
        'You can only re-upload your own recordings',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return;
    }
    
    if (recording.filePath.isEmpty ||
        !await File(recording.filePath).exists()) {
      Get.snackbar(
        'Error',
        'Original recording file not found. Cannot re-upload.',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return;
    }

    try {
      Get.snackbar(
        'Re-uploading',
        'Fixing file format and re-uploading to Drive...',
        showProgressIndicator: true,
        snackPosition: SnackPosition.BOTTOM,
      );

      // Only delete existing Drive file if user is the owner
      // Admins can't delete users' Drive files
      if (recording.driveFileId != null && isOwner) {
        try {
          await _driveService.deleteFile(recording.driveFileId!);
        } catch (e) {
          if (kDebugMode) {
            print('Error deleting old Drive file: $e');
          }
        }
      }

      // Upload with proper MIME type
      final fileId = await _driveService.uploadFile(
        File(recording.filePath),
        recording.title,
        description: 'Hymn: ${recording.hymnId}',
      );

      if (fileId != null) {
        final webLink = await _driveService.getWebViewLink(fileId);
        final updated = recording.copyWith(
          driveFileId: fileId,
          driveWebLink: webLink,
        );
        await _recordingService.updateRecording(updated);

        Get.back(); // Close progress
        Get.snackbar(
          'Success',
          'Recording re-uploaded successfully with correct format',
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      Get.back(); // Close progress
      Get.snackbar(
        'Re-upload Failed',
        'Failed to re-upload recording: $e',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
}

  Future<String?> _showDuplicateTitleDialog(UserRecording recording) async {
    final titleController = TextEditingController(text: recording.title);
    String? errorMessage;

    return await Get.dialog<String>(
      StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Get.theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.orange, size: 24),
              SizedBox(width: 12),
              Text('Duplicate Title'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'A recording with this title already exists for this hymn. Please choose a different title:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: 'Enter new title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  errorText: errorMessage,
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
              onPressed: () => Get.back(result: null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) {
                  setState(() {
                    errorMessage = 'Title cannot be empty';
                  });
                  return;
                }

                // Check if new title also exists
                final titleExists = await _publicService.titleExistsForHymn(
                  recording.hymnId,
                  title,
                );
                if (titleExists) {
                  setState(() {
                    errorMessage = 'This title also exists';
                  });
                  return;
                }

                Get.back(result: title);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Use This Title'),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }
}
