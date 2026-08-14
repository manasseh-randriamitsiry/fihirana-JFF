import 'package:awesome_notifications/awesome_notifications.dart';

class NotificationChannelBuilder {
  static bool _isInitialized = false;

  static Future<void> initializeAllChannels() async {
    if (_isInitialized) return;

    try {
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
      _isInitialized = true;
    } catch (_) {
      // Leave initialization retryable if the platform call fails.
      _isInitialized = false;
      rethrow;
    }

    // Note: Permission request is now handled in the welcome page during onboarding
  }

  static NotificationChannel _createBasicChannel() {
    return NotificationChannel(
      channelKey: 'basic_channel',
      channelName: 'Notifications générales',
      channelDescription: 'Canal pour les notifications générales',
      importance: NotificationImportance.High,
      channelShowBadge: true,
    );
  }

  static NotificationChannel _createAudioPlayerChannel() {
    return NotificationChannel(
      channelKey: 'audio_player_channel',
      channelName: 'Lecteur de musique Fihirana',
      channelDescription: 'Commandes et informations de lecture de Fihirana',
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
      importance: NotificationImportance.High,
      channelShowBadge: true,
      icon: 'resource://mipmap/ic_launcher',
    );
  }

  static NotificationChannel _createDailyVerseChannel() {
    return NotificationChannel(
      channelKey: 'daily_verse_channel',
      channelName: 'Verset biblique du jour',
      channelDescription: 'Versets bibliques quotidiens',
      importance: NotificationImportance.High,
      channelShowBadge: true,
      enableVibration: true,
      enableLights: true,
      playSound: true,
      icon: 'resource://mipmap/ic_launcher',
      locked: false,
      defaultPrivacy: NotificationPrivacy.Public,
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
