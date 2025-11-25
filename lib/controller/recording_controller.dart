import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:just_audio/just_audio.dart'; // Removed unused import
import 'package:uuid/uuid.dart';
import '../models/user_recording.dart';
import '../services/user_recording_service.dart';
import '../services/google_drive_service.dart';
import '../services/public_recording_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hymn.dart';
import '../services/audio_service.dart';
import 'package:fihirana/services/local_audio_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
// We need to import AudioPlayerScreen to navigate to it
import '../screen/player/audio_player_screen.dart';
import '../l10n/app_localizations.dart';

class RecordingController extends GetxController {
  final UserRecordingService _recordingService = UserRecordingService();
  final GoogleDriveService _driveService = GoogleDriveService();
  final PublicRecordingService _publicService = PublicRecordingService();
  final _uuid = const Uuid();

  // Recording state
  final RxBool isRecording = false.obs;
  final RxBool isPaused = false.obs;
  final RxInt recordDuration = 0.obs;
  Timer? _timer;

  // Playback state
  // Removed internal AudioPlayer as we now use AudioService
  // final AudioPlayer _audioPlayer = AudioPlayer();
  // final RxBool isPlaying = false.obs;
  // final RxString currentPlayingId = ''.obs;
  // final Rx<Duration> currentPosition = Duration.zero.obs;
  // final Rx<Duration> totalDuration = Duration.zero.obs;
  // final RxDouble playbackSpeed = 1.0.obs;

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

  @override
  void onInit() {
    super.onInit();
    _initServices();
    _loadGuestName();
    // _setupAudioPlayerListeners(); // No longer needed

    // Auto-refresh recordings when page is accessed
    _autoRefreshRecordings();

    // Load public recordings from Firestore
    refreshPublicRecordings();

    // Start periodic refresh to keep recordings in sync
    _startPeriodicRefresh();
  }

  Future<void> _loadGuestName() async {
    final prefs = await SharedPreferences.getInstance();
    guestName.value = prefs.getString('guest_name') ?? '';
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
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing recordings: $e');
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
      _recordingService.loadRecordings();

      // Check for silent sign-in every 2 minutes (every 4 ticks)
      if (!isDriveSignedIn.value && timer.tick % 4 == 0) {
        _checkForSilentSignIn();
      }

      // Also sync from Drive if signed in (every 5 minutes to avoid API limits)
      if (isDriveSignedIn.value && timer.tick % 10 == 0) {
        syncFromDrive();
      }
    });
  }

  // Check for silent sign-in periodically
  Future<void> _checkForSilentSignIn() async {
    try {
      final currentUser = await _driveService.signInSilently();
      if (currentUser != null) {
        isDriveSignedIn.value = true;
        userEmail.value = currentUser.email;
        if (kDebugMode) {
          print(
              'RecordingController: Periodic check found Drive account: ${currentUser.email}');
        }

        // Auto-sync when account is detected
        await syncFromDrive();
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
    _autoRefreshRecordings();
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

      // Try to silently sign in to detect existing Google account
      try {
        final currentUser = await _driveService.signInSilently();
        if (currentUser != null) {
          isDriveSignedIn.value = true;
          userEmail.value = currentUser.email;
          if (kDebugMode) {
            print(
                'RecordingController: Auto-detected Drive account: ${currentUser.email}');
          }

          // Auto-sync recordings from Drive
          await syncFromDrive();
        } else {
          if (kDebugMode) {
            print(
                'RecordingController: No existing Google Drive account found');
          }
        }
      } catch (e) {
        // Silent sign-in check failed
        if (kDebugMode) {
          print('Drive silent sign-in failed: $e');
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
    await _recordingService.startRecording(hymnId);
    isRecording.value = true;
    isPaused.value = false;
    recordDuration.value = 0;
    _startTimer();

    // Show overlay when recording starts
    showOverlay(hymnId, 'Hymn $hymnId'); // You might want to pass actual title
  }

  Future<UserRecording?> stopRecording(String hymnId, String title) async {
    final filePath = await _recordingService.stopRecording();
    isRecording.value = false;
    isPaused.value = false;
    _timer?.cancel();

    if (filePath != null) {
      final recording = await _recordingService.saveRecording(
        filePath: filePath,
        hymnId: hymnId,
        title: title,
        durationSeconds: recordDuration.value,
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
    await _recordingService.deleteRecording(recording.id);
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
  }

  Future<void> updateRecording(UserRecording recording) async {
    await _recordingService.updateRecording(recording);
  }

  Future<void> renameRecording(UserRecording recording, String newTitle) async {
    final updated = recording.copyWith(title: newTitle);
    await updateRecording(updated);

    // If uploaded to Drive, we might want to rename there too, but that requires an extra API call.
    // For now, we just rename locally.
    recordings.refresh();
  }

  Future<String> getStorageUsage() async {
    int totalBytes = 0;
    for (var rec in recordings) {
      try {
        final file = File(rec.filePath);
        if (await file.exists()) {
          totalBytes += await file.length();
        }
      } catch (e) {
        // ignore
      }
    }

    if (totalBytes < 1024) return '$totalBytes B';
    if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Drive Actions
  Future<void> signInToDrive() async {
    final account = await _driveService.signIn();
    if (account != null) {
      isDriveSignedIn.value = true;
      userEmail.value = account.email;

      if (kDebugMode) {
        print(
            'RecordingController: Manual sign-in successful for ${account.email}');
      }

      // Auto-sync after successful sign-in
      await syncFromDrive();
    }
  }

  Future<void> signOutFromDrive() async {
    await _driveService.signOut();
    isDriveSignedIn.value = false;
    userEmail.value = null;
  }

  Future<void> uploadToDrive(UserRecording recording) async {
    // Remove any existing error for this recording
    uploadErrors.remove(recording.id);

    if (!isDriveSignedIn.value) {
      await signInToDrive();
      if (!isDriveSignedIn.value) {
        uploadErrors[recording.id] = 'Failed to sign in to Google Drive';
        return;
      }
    }

    // Add to uploading set
    uploadingRecordingIds.add(recording.id);
    isUploading.value = true;

    try {
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
        final updated = recording.copyWith(
          driveFileId: fileId,
          driveWebLink: webLink,
        );
        await _recordingService.updateRecording(updated);

        // Remove from uploading set on success
        uploadingRecordingIds.remove(recording.id);
        uploadErrors.remove(recording.id);

        Get.snackbar(
          'Success',
          'Recording uploaded to Drive successfully',
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } else {
        throw Exception('Upload failed - no file ID returned');
      }
    } catch (e) {
      // Store error message
      uploadErrors[recording.id] = e.toString();

      Get.snackbar(
        'Upload Failed',
        'Failed to upload recording: ${e.toString()}',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      // Remove from uploading set
      uploadingRecordingIds.remove(recording.id);
      isUploading.value = uploadingRecordingIds.isNotEmpty;
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

  // Method to retry upload for a failed recording
  Future<void> retryUpload(UserRecording recording) async {
    uploadErrors.remove(recording.id);
    await uploadToDrive(recording);
  }

  // Sync recordings from Google Drive
  Future<void> syncFromDrive() async {
    if (!isDriveSignedIn.value) {
      if (kDebugMode) {
        print('Cannot sync from Drive: Not signed in');
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
          final recording = UserRecording(
            id: _uuid.v4(),
            hymnId: driveFile.description?.split('Hymn: ').last ?? 'unknown',
            title: (driveFile.name ?? '').replaceAll('.m4a', ''),
            filePath: '', // No local file available
            durationSeconds: 0, // Unknown duration
            createdAt:
                DateTime.tryParse(driveFile.createdTime?.toString() ?? '') ??
                    DateTime.now(),
            isPublic: false,
            tags: [],
            driveFileId: driveFile.id ?? '',
            driveWebLink: driveFile.webViewLink,
          );

          // Use saveDriveRecording to add it directly with Drive info
          await _recordingService.saveDriveRecording(recording);

          if (kDebugMode) {
            print('Added new recording from Drive: ${recording.title}');
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
    // Create a fake Hymn object for the player screen
    final hymn = Hymn(
      id: recording.id,
      hymnNumber: recording.hymnId,
      title: recording.title,
      verses: [],
      createdAt: recording.createdAt,
      createdBy: 'User',
    );

    // Navigate to AudioPlayerScreen
    Get.to(() => AudioPlayerScreen(
          hymn: hymn,
          playlist: [hymn],
        ));

    // Start playing
    playRecording(recording);
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

  Future<void> publishRecording(UserRecording recording) async {
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
      final updatedRecording = recording.copyWith(
        isPublic: true,
        driveFileId: driveFileId,
        publicLink: publicLink,
        userName: userName,
      );

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
}
