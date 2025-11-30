import 'package:flutter/foundation.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:fihirana/models/hymn.dart';
import 'package:fihirana/widgets/common/notification_styles.dart';
import 'package:fihirana/widgets/common/audio_player_notification.dart';
import 'package:fihirana/widgets/common/notification_channels.dart';
import 'package:fihirana/services/audio/audio_service.dart';
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
