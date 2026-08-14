import 'package:awesome_notifications/awesome_notifications.dart';
import 'notification_styles.dart';

class AnnouncementNotificationBuilder {
  static Future<void> showNewAnnouncement({
    required String id,
    required String title,
    required String message,
  }) async {
    final notificationId =
        DateTime.now().millisecondsSinceEpoch.remainder(100000);

    final content = NotificationLayouts.createBigTextNotification(
      id: notificationId,
      channelKey: 'announcement_channel',
      title: 'Filazana vaovao: $title',
      body: message,
      payload: id,
    );

    final actionButtons =
        NotificationButtons.createAnnouncementButtons(openKey: 'OPEN');

    await AwesomeNotifications().createNotification(
      content: content,
      actionButtons: actionButtons,
    );
  }

  static Future<void> showAnnouncementCreated({
    String title = 'Fahombiazana',
    String message = 'Voaforona ny filazana',
  }) async {
    final content = NotificationLayouts.createSuccessNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: message,
    );

    await AwesomeNotifications().createNotification(content: content);
  }

  static Future<void> showAnnouncementUpdated({
    String title = 'Fahombiazana',
    String message = 'Voaova ny filazana',
  }) async {
    final content = NotificationLayouts.createSuccessNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: message,
    );

    await AwesomeNotifications().createNotification(content: content);
  }

  static Future<void> showAnnouncementDeleted({
    String title = 'Fahombiazana',
    String message = 'Voafafa ny filazana',
  }) async {
    final content = NotificationLayouts.createSuccessNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: message,
    );

    await AwesomeNotifications().createNotification(content: content);
  }

  static Future<void> showPermissionError({
    String title = 'Tsy manana alalana',
    String message = 'Tsy afaka mamorona filazana ianao',
  }) async {
    final content = NotificationLayouts.createErrorNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: message,
    );

    await AwesomeNotifications().createNotification(content: content);
  }

  static Future<void> showCreateError({
    String? error,
    String title = 'Nisy olana',
    String message = 'Tsy afaka mamorona filazana',
  }) async {
    final errorMessage = error != null ? '$message: $error' : message;

    final content = NotificationLayouts.createErrorNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: errorMessage,
    );

    await AwesomeNotifications().createNotification(content: content);
  }

  static Future<void> showUpdateError({
    String? error,
    String title = 'Nisy olana',
    String message = 'Tsy afaka manova ny filazana',
  }) async {
    final errorMessage = error != null ? '$message: $error' : message;

    final content = NotificationLayouts.createErrorNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: errorMessage,
    );

    await AwesomeNotifications().createNotification(content: content);
  }

  static Future<void> showDeleteError({
    String? error,
    String title = 'Nisy olana',
    String message = 'Tsy afaka mamafa ny filazana',
  }) async {
    final errorMessage = error != null ? '$message: $error' : message;

    final content = NotificationLayouts.createErrorNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: errorMessage,
    );

    await AwesomeNotifications().createNotification(content: content);
  }
}
