import 'package:awesome_notifications/awesome_notifications.dart';
import 'notification_styles.dart';

class UpdateNotificationBuilder {
  static const int notificationId = 1;

  static Future<void> showUpdateAvailable({
    required String version,
    String? releaseNotes,
    String title = 'Misy rindrambaiko vaovao',
    String? downloadUrl,
  }) {
    final body = releaseNotes != null
        ? 'Version $version dia efa azo ampiasaina!\n\nVaovao:\n$releaseNotes'
        : 'Version $version dia efa azo ampiasaina! Tsindrio eto raha haka.';

    final content = NotificationLayouts.createBigTextNotification(
      id: notificationId,
      channelKey: 'basic_channel',
      title: title,
      body: body,
      color: NotificationStyles.primaryColor,
      payload: downloadUrl,
      additionalPayload: {'type': 'update_available', 'version': version},
    );

    final actionButtons = NotificationButtons.createUpdateButtons(
      updateKey: 'UPDATE',
      dismissKey: 'DISMISS',
    );

    return AwesomeNotifications().createNotification(
      content: content,
      actionButtons: actionButtons,
    );
  }

  static Future<void> showInAppUpdateAvailable({
    String title = 'Misy rindrambaiko vaovao',
    String body =
        'Misy Version vaovao efa azo ampiasaina! Tsindrio eto raha haka.',
  }) {
    final content = NotificationLayouts.createBasicNotification(
      id: notificationId,
      channelKey: 'basic_channel',
      title: title,
      body: body,
      color: NotificationStyles.primaryColor,
      payload: 'in_app_update',
    );

    final actionButtons = NotificationButtons.createUpdateButtons(
      updateKey: 'UPDATE',
      dismissKey: 'DISMISS',
    );

    return AwesomeNotifications().createNotification(
      content: content,
      actionButtons: actionButtons,
    );
  }

  static Future<void> showFlexibleUpdateDownloading({
    String title = 'Fakàna rindrambaiko',
    String body = 'Mahandrasa kely azafady.',
  }) {
    final content = NotificationLayouts.createBasicNotification(
      id: notificationId + 2,
      channelKey: 'basic_channel',
      title: title,
      body: body,
      color: NotificationStyles.primaryColor,
      payload: 'flexible_update_complete',
    );

    return AwesomeNotifications().createNotification(content: content);
  }

  static Future<void> showDownloadError({
    String? error,
    String title = 'Tsy afaka naka',
    String body = 'Nisy olana fa avereno alaina rehefa afaka kelikely.',
  }) {
    final errorMessage = error != null ? '$body: $error' : body;

    final content = NotificationLayouts.createErrorNotification(
      id: notificationId + 1,
      title: title,
      body: errorMessage,
    );

    return AwesomeNotifications().createNotification(content: content);
  }

  static Future<void> showInstallError({
    String? error,
    String title = 'Tsy afaka naka',
    String body =
        'Tsy afaka naka ny rindrambaiko vaovao. Avereno alaina rehefa afaka kelikely azafady.',
  }) {
    final errorMessage = error != null ? '$body: $error' : body;

    final content = NotificationLayouts.createErrorNotification(
      id: notificationId + 1,
      title: title,
      body: errorMessage,
    );

    return AwesomeNotifications().createNotification(content: content);
  }
}
