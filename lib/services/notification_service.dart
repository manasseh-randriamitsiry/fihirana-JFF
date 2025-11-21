import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import '../models/hymn.dart';
import '../services/audio_service.dart';
import 'package:get/get.dart';

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

  static void showAudioPlayerNotification(Hymn hymn, bool isPlaying) {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: audioPlayerNotificationId,
        channelKey: 'audio_player_channel',
        title: hymn.title,
        body: 'Hira ${hymn.hymnNumber}',
        category: NotificationCategory.Transport,
        notificationLayout: NotificationLayout.MediaPlayer,
        color: Colors.blue,
        autoDismissible: false,
        displayOnForeground: true,
        displayOnBackground: true,
        wakeUpScreen: false, // Don't wake up screen on every update
        fullScreenIntent: false,
        locked: true,
        backgroundColor: Colors.black87,
        summary: 'Fihirana Audio',
        largeIcon:
            'resource://mipmap/ic_launcher', // Use app icon as album art placeholder
        roundedLargeIcon: true,
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

  static void updateAudioPlayerNotification(Hymn? hymn, bool isPlaying) {
    if (hymn != null) {
      showAudioPlayerNotification(hymn, isPlaying);
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
      ],
    );
  }
}
