import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as path;
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/recording/domain/entities/user_recording.dart';
import 'package:fihirana/features/audio/data/services/audio_service.dart';
import 'package:fihirana/features/recording/data/services/recording_service.dart';
import 'package:fihirana/features/audio/data/services/local_audio_service.dart';
import 'package:fihirana/features/recording/data/services/google_drive_service.dart';
import 'package:fihirana/core/utils/ui_service.dart';
import 'package:fihirana/core/utils/notification_service.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'recording_state_manager.dart';

/// Manages playback functionality
class RecordingPlaybackManager extends GetxController {
  final RecordingStateManager _stateManager;
  final RecordingService _recordingService;
  final Rxn<UserRecording> currentRecording = Rxn<UserRecording>();

  // Dedicated player for recordings to avoid affecting the main AudioService state
  final AudioPlayer _player = AudioPlayer();
  final LocalAudioService _localAudioService = LocalAudioService();

  RecordingPlaybackManager({
    required RecordingStateManager stateManager,
    required RecordingService recordingService,
  })  : _stateManager = stateManager,
        _recordingService = recordingService;

  @override
  void onInit() {
    super.onInit();
    _initializePlayerListeners();
  }

  @override
  void onClose() {
    _player.dispose();
    super.onClose();
  }

  void _initializePlayerListeners() {
    // Listen to player state to update UI and notifications
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        // Handle completion - hide notification
        NotificationService.hideAudioPlayerNotification();
      }

      // Update notification when play/pause state changes
      final recording = currentRecording.value;
      if (recording != null) {
        _updateNotification(recording, state.playing);
      }
    });

    // Listen to position changes to update notification progress
    _player.positionStream.listen((position) {
      final recording = currentRecording.value;
      if (recording != null) {
        _updateNotification(recording, _player.playing);
      }
    });
  }

  /// Update or create notification for recording playback
  void _updateNotification(UserRecording recording, bool isPlaying) {
    // Create a Hymn object to use with the notification system
    final hymn = Hymn(
      id: 'recording_${recording.id}',
      hymnNumber: recording.hymnId,
      title: recording.title,
      verses: [],
      createdAt: recording.createdAt,
      createdBy: 'User: ${recording.userName ?? 'Anonymous'}',
    );

    NotificationService.updateAudioPlayerProgress(
      hymn,
      isPlaying,
      position: _player.position,
      duration: _player.duration,
    );
  }

  // Playback Actions
  Future<void> playRecording(UserRecording recording) async {
    try {
      // Pause the main audio service to avoid playing both at the same time
      // but DO NOT change its state (current hymn, etc.)
      if (AudioService.instance.isPlaying) {
        await AudioService.instance.pause();
      }

      currentRecording.value = recording;

      final audioUrl = await _resolveAudioUrl(recording);
      if (audioUrl == null) {
        throw Exception('Could not resolve audio URL for recording');
      }

      // Play using the local player
      if (audioUrl.startsWith('http')) {
        await _player.setUrl(audioUrl);
      } else {
        await _player.setFilePath(audioUrl);
      }

      await _player.play();
    } catch (e) {
      if (kDebugMode) print('Error playing recording: $e');
      Get.snackbar('Error', 'Failed to play recording: $e');
    }
  }

  Future<String?> _resolveAudioUrl(UserRecording recording) async {
    String? audioUrl;
    String targetPath = recording.filePath;

    // PRIORITY 1: Check if recording is public and has a Drive ID
    if (recording.isPublic && recording.driveFileId != null) {
      audioUrl =
          'https://drive.google.com/uc?export=download&id=${recording.driveFileId}';
    }
    // Check if recording has a public link (fallback)
    else if (recording.publicLink != null && recording.publicLink!.isNotEmpty) {
      audioUrl = recording.publicLink!;
      if (audioUrl.contains('drive.google.com')) {
        final idMatch = RegExp(r'[?&]id=([^&]+)').firstMatch(audioUrl);
        if (idMatch != null) {
          audioUrl =
              'https://drive.google.com/uc?export=download&id=${idMatch.group(1)}';
        }
      }
    }
    // PRIORITY 2: Check if local file exists
    else if (targetPath.isNotEmpty) {
      final file = File(targetPath);
      if (await file.exists()) {
        audioUrl = targetPath;
      }
    } else {
      // Generate a path if one doesn't exist
      final stats = await _localAudioService.getStorageStats();
      final dir = stats['directory'] as String;
      targetPath = path.join(dir, 'recording_${recording.id}.m4a');

      final file = File(targetPath);
      if (await file.exists()) {
        audioUrl = targetPath;
      }
    }

    // PRIORITY 3: If no local file and no public link, try authenticated URL for private recordings
    if (audioUrl == null && recording.driveFileId != null) {
      try {
        final driveService = GoogleDriveService();
        if (!driveService.isSignedIn) {
          await driveService.signInSilently();
        }

        if (driveService.isSignedIn) {
          final authenticatedUrl = await driveService
              .getAuthenticatedDownloadUrl(recording.driveFileId!);
          if (authenticatedUrl != null) {
            audioUrl = authenticatedUrl;
          } else {
            // Fallback to downloading
            UIService.showAudioDownloadingSnackBar();

            String finalTargetPath = targetPath;
            if (!finalTargetPath.toLowerCase().endsWith('.m4a')) {
              finalTargetPath = '$finalTargetPath.m4a';
            }

            final downloadedFile = await driveService.downloadFile(
              recording.driveFileId!,
              finalTargetPath,
            );

            if (downloadedFile != null && await downloadedFile.exists()) {
              audioUrl = downloadedFile.path;
            }
          }
        }
      } catch (e) {
        if (kDebugMode) print('Error resolving Drive URL: $e');
      }
    }

    return audioUrl;
  }

  Future<void> pausePlayback() async {
    await _player.pause();
  }

  Future<void> resumePlayback() async {
    await _player.play();
  }

  Future<void> stopPlayback() async {
    await _player.stop();
    NotificationService.hideAudioPlayerNotification();
  }

  Future<void> seekPlayback(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  /// Refresh public URLs for all recordings
  Future<void> refreshPublicUrls() async {
    try {
      await _recordingService.refreshPublicUrls();
      Get.snackbar('Success', 'Public URLs refreshed successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to refresh URLs: $e');
    }
  }

  // Player UI management
  void showPlayer(UserRecording recording,
      {required bool isRecording, required VoidCallback onStopRecording}) {
    if (isRecording) {
      _showStopRecordingDialog(recording, onStopRecording);
      return;
    }

    if (_stateManager.overlayVisible.value) {
      _stateManager.hideOverlay();
    }

    _proceedWithPlayback(recording);
  }

  void hidePlayer() {
    _stateManager.hidePlayerOverlay();
    currentRecording.value = null;
    stopPlayback();
    NotificationService.hideAudioPlayerNotification();
  }

  void minimizePlayer() {
    _stateManager.minimizePlayer();
  }

  void restorePlayer() {
    _stateManager.restorePlayer();
  }

  bool shouldShowPlayerOverlay() {
    return _stateManager.shouldShowPlayerOverlay();
  }

  void _showStopRecordingDialog(
      UserRecording recording, VoidCallback onStopRecording) {
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
              onStopRecording();
              _stateManager.hideOverlay();
              _proceedWithPlayback(recording);
            },
            child: Text(l10n.stopAndPlay),
          ),
        ],
      ),
    );
  }

  void _proceedWithPlayback(UserRecording recording) {
    // Play recording directly without showing the compact player widget
    // This avoids conflicts with the main audio player
    playRecording(recording);

    // Show a simple snackbar to indicate playback started
    Get.snackbar(
      'Playing Recording',
      recording.title,
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // Expose player state for UI
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
}
