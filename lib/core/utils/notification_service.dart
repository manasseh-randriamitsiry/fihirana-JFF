import 'package:flutter/foundation.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/shared/widgets/common/notification_styles.dart';
import 'package:fihirana/shared/widgets/common/audio_player_notification.dart';
import 'package:fihirana/shared/widgets/common/notification_channels.dart';
import 'package:fihirana/features/audio/data/services/audio_service.dart';
import 'package:fihirana/features/recording/presentation/controllers/recording_controller.dart';
import 'version_check_service.dart';

class NotificationService {
  static const int audioPlayerNotificationId = 1001;

  static void showSuccessNotification(String title, String body) {
    NotificationLayouts.createSuccessNotification(
      id: createUniqueId(),
      title: title,
      body: body,
    );
  }

  static void showErrorNotification(String title, String body) {
    NotificationLayouts.createErrorNotification(
      id: createUniqueId(),
      title: title,
      body: body,
    );
  }

  static void showAudioPlayerNotification(Hymn hymn, bool isPlaying,
      {Duration? position, Duration? duration}) {
    // Delegate to update method for consistency
    updateAudioPlayerProgress(hymn, isPlaying,
        position: position, duration: duration);
  }

  static void updateAudioPlayerProgress(Hymn hymn, bool isPlaying,
      {Duration? position, Duration? duration}) {
    final audioService = AudioService.instance;
    final canGoNext = audioService.canGoNext;
    final canGoPrev = audioService.canGoPrevious;

    AudioPlayerNotificationBuilder.updateNotification(
      hymn: hymn,
      isPlaying: isPlaying,
      position: position,
      duration: duration,
      canGoNext: canGoNext,
      canGoPrevious: canGoPrev,
    );
  }

  static void updateAudioPlayerNotification(Hymn? hymn, bool isPlaying,
      {Duration? position, Duration? duration}) {
    if (hymn != null) {
      updateAudioPlayerProgress(hymn, isPlaying,
          position: position, duration: duration);
    } else {
      hideAudioPlayerNotification();
    }
  }

  static void hideAudioPlayerNotification() {
    AudioPlayerNotificationBuilder.hideNotification();
  }

  static void forceClearAudioNotification() {
    AudioPlayerNotificationBuilder.forceClearAllNotifications();
  }

  static int createUniqueId() {
    return DateTime.now().millisecondsSinceEpoch.remainder(100000);
  }

  static Future<void> initializeNotificationChannels() async {
    await NotificationChannelBuilder.initializeAllChannels();
  }

  /// Setup notification action listeners for audio player controls
  static void setupNotificationListeners() {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onNotificationActionReceived,
    );
  }

  /// Handle notification action button clicks
  @pragma('vm:entry-point')
  static Future<void> onNotificationActionReceived(
      ReceivedAction receivedAction) async {
    try {
      if (kDebugMode) {
        print(
            'Notification action received: ${receivedAction.buttonKeyPressed}');
      }

      // Handle audio player actions
      if (receivedAction.buttonKeyPressed == 'prev' ||
          receivedAction.buttonKeyPressed == 'play' ||
          receivedAction.buttonKeyPressed == 'pause' ||
          receivedAction.buttonKeyPressed == 'next' ||
          receivedAction.buttonKeyPressed == 'stop' ||
          receivedAction.buttonKeyPressed == 'rewind' ||
          receivedAction.buttonKeyPressed == 'forward') {
        await _handleAudioPlayerAction(receivedAction);
        return;
      }

      // Handle version check/update actions
      if (receivedAction.buttonKeyPressed == 'UPDATE' ||
          receivedAction.buttonKeyPressed == 'DISMISS' ||
          receivedAction.buttonKeyPressed == 'CANCEL_DOWNLOAD') {
        await _handleUpdateAction(receivedAction);
        return;
      }

      if (kDebugMode) {
        print('Unknown action: ${receivedAction.buttonKeyPressed}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling notification action: $e');
      }
    }
  }

  /// Handle audio player notification actions
  static Future<void> _handleAudioPlayerAction(
      ReceivedAction receivedAction) async {
    // Check if a recording is currently playing
    bool isRecordingPlaying = false;
    RecordingController? recordingController;

    try {
      if (Get.isRegistered<RecordingController>()) {
        recordingController = Get.find<RecordingController>();
        isRecordingPlaying =
            recordingController.playbackManager.currentRecording.value != null;
      }
    } catch (e) {
      // RecordingController not initialized, fall back to AudioService
      if (kDebugMode) print('RecordingController not available: $e');
    }

    if (isRecordingPlaying && recordingController != null) {
      // Route to RecordingPlaybackManager
      await _handleRecordingPlayerAction(receivedAction, recordingController);
    } else {
      // Route to AudioService for hymn playback
      await _handleHymnPlayerAction(receivedAction);
    }
  }

  /// Handle notification actions for recording playback
  static Future<void> _handleRecordingPlayerAction(
      ReceivedAction receivedAction,
      RecordingController recordingController) async {
    final playbackManager = recordingController.playbackManager;

    switch (receivedAction.buttonKeyPressed) {
      case 'play':
        if (kDebugMode) print('Resuming recording playback');
        await playbackManager.resumePlayback();
        break;

      case 'pause':
        if (kDebugMode) print('Pausing recording playback');
        await playbackManager.pausePlayback();
        break;

      case 'stop':
        if (kDebugMode) print('Stopping recording playback');
        await playbackManager.stopPlayback();
        hideAudioPlayerNotification();
        break;

      case 'rewind':
        if (kDebugMode) print('Rewinding recording 10 seconds');
        final currentPos = playbackManager.position;
        final newPos = currentPos - const Duration(seconds: 10);
        await playbackManager
            .seekPlayback(newPos.isNegative ? Duration.zero : newPos);
        break;

      case 'forward':
        if (kDebugMode) print('Forwarding recording 10 seconds');
        final currentPos = playbackManager.position;
        final duration = playbackManager.duration;
        if (duration != null) {
          final newPos = currentPos + const Duration(seconds: 10);
          await playbackManager
              .seekPlayback(newPos > duration ? duration : newPos);
        }
        break;

      // Note: prev/next not supported for single recording playback
      case 'prev':
      case 'next':
        if (kDebugMode) print('Prev/Next not supported for recording playback');
        break;
    }
  }

  /// Handle notification actions for hymn playback
  static Future<void> _handleHymnPlayerAction(
      ReceivedAction receivedAction) async {
    final audioService = AudioService.instance;

    switch (receivedAction.buttonKeyPressed) {
      case 'prev':
        if (audioService.canGoPrevious) {
          if (kDebugMode) print('Playing previous track');
          await audioService.playPrevious();
        } else {
          if (kDebugMode) print('Previous track not available');
        }
        break;

      case 'play':
        if (kDebugMode) print('Resuming playback');
        await audioService.resume();
        break;

      case 'pause':
        if (kDebugMode) print('Pausing playback');
        await audioService.pause();
        break;

      case 'next':
        if (audioService.canGoNext) {
          if (kDebugMode) print('Playing next track');
          await audioService.playNext();
        } else {
          if (kDebugMode) print('Next track not available');
        }
        break;

      case 'rewind':
        if (kDebugMode) print('Rewinding 10 seconds');
        final currentPosition = audioService.currentPosition;
        if (currentPosition != null) {
          final newPosition = currentPosition - const Duration(seconds: 10);
          final seekPosition =
              newPosition.isNegative ? Duration.zero : newPosition;
          await audioService.seekTo(seekPosition);
        }
        break;

      case 'forward':
        if (kDebugMode) print('Forwarding 10 seconds');
        final currentPosition = audioService.currentPosition;
        final duration = audioService.duration;
        if (currentPosition != null && duration != null) {
          final newPosition = currentPosition + const Duration(seconds: 10);
          final seekPosition = newPosition > duration ? duration : newPosition;
          await audioService.seekTo(seekPosition);
        }
        break;

      case 'stop':
        if (kDebugMode) print('Stopping playback');
        await audioService.stop();
        hideAudioPlayerNotification();
        break;
    }
  }

  /// Handle version check/update notification actions
  static Future<void> _handleUpdateAction(ReceivedAction receivedAction) async {
    // Delegate to VersionCheckService handler
    await VersionCheckService.onActionReceivedMethod(receivedAction);
  }
}
