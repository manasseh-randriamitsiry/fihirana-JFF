import 'package:awesome_notifications/awesome_notifications.dart';
import 'notification_styles.dart';

class DailyVerseNotificationBuilder {
  static const int notificationId = 100;

  static Future<void> scheduleDailyVerse({
    required String reference,
    required String text,
    required String book,
    required int chapter,
    required int verse,
    required int hour,
    required int minute,
  }) async {
    final content = NotificationLayouts.createBigTextNotification(
      id: notificationId,
      channelKey: 'daily_verse_channel',
      title: '📖 $reference',
      body: text,
      color: NotificationStyles.dailyVerseColor,
      additionalPayload: {
        'book': book,
        'chapter': chapter.toString(),
        'verse': verse.toString(),
        'type': 'daily_verse',
      },
    );

    await AwesomeNotifications().createNotification(
      content: content,
      schedule: NotificationCalendar(
        hour: hour,
        minute: minute,
        second: 0,
        repeats: true,
        allowWhileIdle: true,
      ),
    );
  }

  static Future<void> cancelDailyVerseNotifications() async {
    await AwesomeNotifications().cancel(notificationId);
  }

  static Future<void> sendTestNotification({
    required String reference,
    required String text,
    required String book,
    required int chapter,
    required int verse,
  }) async {
    final content = NotificationLayouts.createBigTextNotification(
      id: 101, // Different ID for test
      channelKey: 'daily_verse_channel',
      title: '📖 $reference',
      body: text,
      color: NotificationStyles.dailyVerseColor,
      additionalPayload: {
        'book': book,
        'chapter': chapter.toString(),
        'verse': verse.toString(),
        'type': 'daily_verse',
      },
    );

    await AwesomeNotifications().createNotification(content: content);
  }

  static Future<void> cancelTestNotification() async {
    await AwesomeNotifications().cancel(101);
  }
}