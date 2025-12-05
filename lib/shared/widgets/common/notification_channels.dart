import 'package:awesome_notifications/awesome_notifications.dart';
import 'notification_styles.dart';

class NotificationChannelBuilder {
  static Future<void> initializeAllChannels() async {
    await AwesomeNotifications().initialize(
      'resource://mipmap/ic_launcher',
      [
        _createBasicChannel(),
        _createAudioPlayerChannel(),
        _createAnnouncementChannel(),
        _createHymnDownloadChannel(),
        _createDailyVerseChannel(),
      ],
      debug: true,
    );

    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  static NotificationChannel _createBasicChannel() {
    return NotificationChannel(
      channelKey: 'basic_channel',
      channelName: 'Basic notifications',
      channelDescription: 'Notification channel for basic notifications',
      defaultColor: NotificationStyles.primaryColor,
      importance: NotificationImportance.High,
      channelShowBadge: true,
    );
  }

  static NotificationChannel _createAudioPlayerChannel() {
    return NotificationChannel(
      channelKey: 'audio_player_channel',
      channelName: 'Fihirana Music Player',
      channelDescription: 'Fihirana music player controls and playback information',
      defaultColor: NotificationStyles.audioPlayerColor,
      importance: NotificationImportance.Low,
      channelShowBadge: false,
      playSound: false,
      enableVibration: false,
      onlyAlertOnce: true,
      criticalAlerts: false,
      locked: true,
      defaultPrivacy: NotificationPrivacy.Public,
    );
  }

  static NotificationChannel _createAnnouncementChannel() {
    return NotificationChannel(
      channelKey: 'announcement_channel',
      channelName: 'Filazana',
      channelDescription: 'Notifications for announcements',
      defaultColor: NotificationStyles.primaryColor,
      importance: NotificationImportance.High,
      channelShowBadge: true,
      enableVibration: true,
      enableLights: true,
      defaultPrivacy: NotificationPrivacy.Public,
      playSound: true,
      icon: 'resource://mipmap/ic_launcher',
    );
  }

  static NotificationChannel _createHymnDownloadChannel() {
    return NotificationChannel(
      channelKey: 'hymn_download_channel',
      channelName: 'Maka Hira',
      channelDescription: 'Notifications for hymn downloads and updates',
      defaultColor: NotificationStyles.primaryColor,
      importance: NotificationImportance.High,
      channelShowBadge: true,
      icon: 'resource://mipmap/ic_launcher',
    );
  }

  static NotificationChannel _createDailyVerseChannel() {
    return NotificationChannel(
      channelKey: 'daily_verse_channel',
      channelName: 'Daily Bible Verse',
      channelDescription: 'Daily inspirational Bible verses',
      defaultColor: NotificationStyles.dailyVerseColor,
      importance: NotificationImportance.High,
      channelShowBadge: true,
      enableVibration: true,
      enableLights: true,
      playSound: true,
      icon: 'resource://mipmap/ic_launcher',
      locked: false,
      defaultPrivacy: NotificationPrivacy.Public,
      ledColor: NotificationStyles.dailyVerseColor,
      ledOnMs: 1000,
      ledOffMs: 500,
    );
  }

  static Future<void> requestPermissions() async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  static Future<bool> hasPermission() async {
    return await AwesomeNotifications().isNotificationAllowed();
  }
}