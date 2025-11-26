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
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: audioPlayerNotificationId,
        channelKey: 'audio_player_channel',
        title: hymn.title,
        body: 'Hira ${hymn.hymnNumber}',
        category: NotificationCategory.Transport,
        notificationLayout: NotificationLayout.MediaPlayer,
        color: Colors.blue,
        autoDismissible: !isPlaying, // Allow dismissal when paused
        displayOnForeground: true,
        displayOnBackground: true,
        wakeUpScreen: false, // Don't wake up screen on every update
        fullScreenIntent: false,
        locked: isPlaying, // Only lock notification when playing
        backgroundColor: Colors.black87,
        summary: 'Fihirana Audio',
        largeIcon:
            'resource://mipmap/ic_launcher', // Use app icon as album art placeholder
        roundedLargeIcon: true,
        // Add progress for timeline display
        progress: position != null && duration != null && duration.inSeconds > 0
            ? (position.inSeconds / duration.inSeconds) * 100
            : null,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'prev',
          label: 'Previous',
          icon: 'resource://drawable/ic_skip_previous',
          enabled: true,
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
          enabled: true,
          autoDismissible: false,
          showInCompactView: true,
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

  static void hideAudioPlayerNotification() {
    AwesomeNotifications().dismiss(audioPlayerNotificationId);
  }

  static void updateAudioPlayerNotification(Hymn? hymn, bool isPlaying,
      {Duration? position, Duration? duration}) {
    if (hymn != null) {
      showAudioPlayerNotification(hymn, isPlaying,
          position: position, duration: duration);
    } else {
      hideAudioPlayerNotification();
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
        print(
            'Notification action received: ${receivedAction.buttonKeyPressed}');
      }

      // Handle audio player actions
      if (receivedAction.buttonKeyPressed == 'prev' ||
          receivedAction.buttonKeyPressed == 'play' ||
          receivedAction.buttonKeyPressed == 'pause' ||
          receivedAction.buttonKeyPressed == 'next' ||
          receivedAction.buttonKeyPressed == 'stop') {
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
        if (kDebugMode) print('Playing previous track');
        await audioService.playPrevious();
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
        if (kDebugMode) print('Playing next track');
        await audioService.playNext();
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
