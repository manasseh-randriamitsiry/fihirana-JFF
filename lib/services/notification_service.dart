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
        body: 'Hymn ${hymn.hymnNumber}',
        category: NotificationCategory.Transport,
        notificationLayout: NotificationLayout.MediaPlayer,
        color: Colors.blue,
        autoDismissible: false,
        displayOnForeground: true,
        displayOnBackground: true,
        wakeUpScreen: true,
        fullScreenIntent: false,
        locked: true,
        backgroundColor: Colors.black87,
        summary: 'Fihirana Audio Player',
        largeIcon: 'resource://mipmap/ic_launcher',
        icon: 'resource://mipmap/ic_launcher',
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'prev',
          label: 'Previous',
          icon: 'resource://drawable/ic_skip_previous',
        ),
        NotificationActionButton(
          key: isPlaying ? 'pause' : 'play',
          label: isPlaying ? 'Pause' : 'Play',
          icon: isPlaying ? 'resource://drawable/ic_pause' : 'resource://drawable/ic_play',
        ),
        NotificationActionButton(
          key: 'next',
          label: 'Next',
          icon: 'resource://drawable/ic_skip_next',
        ),
        NotificationActionButton(
          key: 'stop',
          label: 'Stop',
          icon: 'resource://drawable/ic_stop',
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
      null,
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
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: false,
          enableVibration: false,
          onlyAlertOnce: false,
          criticalAlerts: false,
        ),
      ],
    );
  }
}
