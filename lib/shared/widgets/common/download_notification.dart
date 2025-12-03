import 'package:awesome_notifications/awesome_notifications.dart';
import 'notification_styles.dart';

class DownloadNotificationBuilder {
  static const int notificationId = 1001;

  static Future<void> showDownloadStarted({
    String title = 'Maka fanavaozana...',
    String body = '0%',
    int progress = 0,
    bool showCancelButton = true,
  }) async {
    final actionButtons = showCancelButton
        ? NotificationButtons.createDownloadButtons(cancelKey: 'CANCEL_DOWNLOAD')
        : null;

    final content = NotificationLayouts.createProgressBarNotification(
      id: notificationId,
      channelKey: 'hymn_download_channel',
      title: 'Fangalana fanavaozana',
      body: body,
      progress: progress.toDouble(),
      color: NotificationStyles.primaryColor,
      locked: true,
      autoDismissible: false,
      actionButtons: actionButtons,
    );

    await AwesomeNotifications().createNotification(content: content);
  }

  static Future<void> updateDownloadProgress({
    required int progress,
    String title = 'Fangalana fanavaozana',
  }) async {
    final body = 'Fangalana... $progress%';
    
    final content = NotificationLayouts.createProgressBarNotification(
      id: notificationId,
      channelKey: 'hymn_download_channel',
      title: title,
      body: body,
      progress: progress.toDouble(),
      color: NotificationStyles.primaryColor,
      locked: true,
      autoDismissible: false,
      actionButtons: NotificationButtons.createDownloadButtons(
        cancelKey: 'CANCEL_DOWNLOAD',
        showCancel: progress < 100,
      ),
    );

    await AwesomeNotifications().createNotification(content: content);
  }

  static Future<void> showDownloadComplete({
    required String fileName,
    String title = 'Vita ny fangalana',
  }) async {
    final content = NotificationLayouts.createSuccessNotification(
      id: notificationId,
      title: title,
      body: 'Voaray ny fanavaozana $fileName',
    );

    await AwesomeNotifications().createNotification(content: content);
  }

  static Future<void> showDownloadError({
    String? error,
    String title = 'Tsy nety',
    String body = 'Nisy olana teo ampanavaozana',
  }) async {
    final errorMessage = error != null ? '$body: $error' : body;
    
    final content = NotificationLayouts.createErrorNotification(
      id: notificationId + 1,
      title: title,
      body: errorMessage,
    );

    await AwesomeNotifications().createNotification(content: content);
  }

  static Future<void> showInstallError({
    String? error,
    String title = 'Nisy olana',
    String body = 'Tsy afaka nametraka ny fanavaozana',
  }) async {
    final errorMessage = error != null ? '$body: $error' : body;
    
    final content = NotificationLayouts.createErrorNotification(
      id: notificationId + 2,
      title: title,
      body: errorMessage,
    );

    await AwesomeNotifications().createNotification(content: content);
  }

  static Future<void> showCancelled({
    String title = 'Ajanona',
    String body = 'Najanony ny fanavaozana',
  }) async {
    final content = NotificationLayouts.createBasicNotification(
      id: notificationId + 3,
      channelKey: 'hymn_download_channel',
      title: title,
      body: body,
      color: NotificationStyles.primaryColor,
    );

    await AwesomeNotifications().createNotification(content: content);
  }
}