import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/hymn.dart';
import 'audio_service.dart';
import 'version_check_service.dart';

class NotificationService {
  static const int audioPlayerNotificationId = 1001;

  static void showSuccessNotification(String title, String body) {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: createUniqueId(),
          channelKey: 'basic_channel',
          title: title,
          body: body,
          color: Colors.green,
          notificationLayout: NotificationLayout.Inbox,
          badge: AwesomeNotifications.maxID),
    );
  }

  static void showErrorNotification(String title, String body) {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: createUniqueId(),
        channelKey: 'basic_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  static void showAudioPlayerNotification(Hymn hymn, bool isPlaying,
      {Duration? position, Duration? duration}) {
    // Delegate to update method for consistency
    updateAudioPlayerProgress(hymn, isPlaying, position: position, duration: duration);
  }

  static void updateAudioPlayerProgress(Hymn hymn, bool isPlaying,
      {Duration? position, Duration? duration}) {
    final audioService = AudioService.instance;
    final canGoNext = audioService.canGoNext;
    final canGoPrev = audioService.canGoPrevious;
    
    // Calculate progress percentage
    double? progress;
    if (position != null && duration != null && duration.inMilliseconds > 0) {
      progress = (position.inMilliseconds.toDouble() / duration.inMilliseconds.toDouble()) * 100;
      progress = progress.clamp(0.0, 100.0); // Ensure progress is within bounds
    }
    
    // Format position and duration for display
    String positionText = '';
    String durationText = '';
    if (position != null) {
      final minutes = position.inMinutes;
      final seconds = position.inSeconds % 60;
      positionText = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    if (duration != null) {
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      durationText = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    
    String body = 'Hira faha ${hymn.hymnNumber}';
    if (positionText.isNotEmpty && durationText.isNotEmpty) {
      body += ' • $positionText / $durationText';
    }
    
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: audioPlayerNotificationId,
        channelKey: 'audio_player_channel',
        title: hymn.title,
        body: body,
        category: NotificationCategory.Transport,
        notificationLayout: NotificationLayout.MediaPlayer,
        color: Colors.blue,
        autoDismissible: !isPlaying, // Allow dismissal when paused
        displayOnForeground: true,
        displayOnBackground: true,
        wakeUpScreen: false,
        fullScreenIntent: false,
        locked: isPlaying, // Only lock notification when playing
        backgroundColor: Colors.black87,
        summary: 'Fihirana Audio',
        largeIcon:
            'resource://mipmap/ic_launcher', // Use app icon as album art placeholder
        roundedLargeIcon: true,
        // Add progress for timeline display - use double precision
        progress: progress,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'prev',
          label: 'Previous',
          icon: 'resource://drawable/ic_skip_previous',
          enabled: canGoPrev,
          autoDismissible: false,
          showInCompactView: true,
        ),
        NotificationActionButton(
          key: isPlaying ? 'pause' : 'play',
          label: isPlaying ? 'Pause' : 'Play',
          icon: isPlaying
              ? 'resource://drawable/ic_pause'
              : 'resource://drawable/ic_play',
          enabled: true,
          autoDismissible: false,
          showInCompactView: true,
        ),
        NotificationActionButton(
          key: 'next',
          label: 'Next',
          icon: 'resource://drawable/ic_skip_next',
          enabled: canGoNext,
          autoDismissible: false,
          showInCompactView: true,
        ),
        NotificationActionButton(
          key: 'rewind',
          label: '-10s',
          icon: 'resource://drawable/ic_rewind',
          enabled: true,
          autoDismissible: false,
          showInCompactView: false,
        ),
        NotificationActionButton(
          key: 'forward',
          label: '+10s',
          icon: 'resource://drawable/ic_forward',
          enabled: true,
          autoDismissible: false,
          showInCompactView: false,
        ),
        NotificationActionButton(
          key: 'stop',
          label: 'Stop',
          icon: 'resource://drawable/ic_stop',
          enabled: true,
          autoDismissible: false,
          showInCompactView: false,
        ),
      ],
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
    try {
      // Try to dismiss the specific notification first
      AwesomeNotifications().dismiss(audioPlayerNotificationId);
      
      // Also try to cancel all notifications as fallback
      AwesomeNotifications().cancelAll();
      
      if (kDebugMode) {
        print('NotificationService: Hid audio player notification');
      }
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: Error hiding notification: $e');
      }
    }
  }

  static void forceClearAudioNotification() {
    try {
      // Force clear all audio player notifications
      AwesomeNotifications().cancelAll();
      
      if (kDebugMode) {
        print('NotificationService: Force cleared all audio notifications');
      }
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: Error force clearing notifications: $e');
      }
    }
  }

  static int createUniqueId() {
    return DateTime.now().millisecondsSinceEpoch.remainder(100000);
  }

  static Future<void> initializeNotificationChannels() async {
    await AwesomeNotifications().initialize(
      'resource://mipmap/ic_launcher',
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic notifications',
          channelDescription: 'Notification channel for basic notifications',
          defaultColor: Colors.blue,
          importance: NotificationImportance.High,
          channelShowBadge: true,
        ),
        NotificationChannel(
          channelKey: 'audio_player_channel',
          channelName: 'Audio Player',
          channelDescription: 'Audio player controls and information',
          defaultColor: Colors.blue,
          importance: NotificationImportance.Low,
          channelShowBadge: false,
          playSound: false,
          enableVibration: false,
          onlyAlertOnce: true,
          criticalAlerts: false,
          locked: true,
          defaultPrivacy: NotificationPrivacy.Public,
        ),
        NotificationChannel(
          channelKey: 'announcement_channel',
          channelName: 'Filazana',
          channelDescription: 'Notifications for announcements',
          defaultColor: const Color(0xFF9D50DD),
          importance: NotificationImportance.High,
          channelShowBadge: true,
          enableVibration: true,
          enableLights: true,
          defaultPrivacy: NotificationPrivacy.Public,
          playSound: true,
          icon: 'resource://mipmap/ic_launcher',
        ),
        NotificationChannel(
          channelKey: 'hymn_download_channel',
          channelName: 'Maka Hira',
          channelDescription: 'Notifications for hymn downloads and updates',
          defaultColor: const Color(0xFF9D50DD),
          importance: NotificationImportance.High,
          channelShowBadge: true,
          icon: 'resource://mipmap/ic_launcher',
        ),
        NotificationChannel(
          channelKey: 'daily_verse_channel',
          channelName: 'Daily Bible Verse',
          channelDescription: 'Daily inspirational Bible verses',
          defaultColor: const Color(0xFF4CAF50),
          importance: NotificationImportance.High,
          channelShowBadge: true,
          enableVibration: true,
          enableLights: true,
          playSound: true,
          icon: 'resource://mipmap/ic_launcher',
          locked: false, // User can customize
          defaultPrivacy: NotificationPrivacy.Public, // Show on lock screen
          ledColor: const Color(0xFF4CAF50),
          ledOnMs: 1000,
          ledOffMs: 500,
        ),
      ],
    );
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
        print('Notification action received: ${receivedAction.buttonKeyPressed}');
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
          final seekPosition = newPosition.isNegative ? Duration.zero : newPosition;
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