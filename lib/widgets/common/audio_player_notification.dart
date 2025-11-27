import 'package:awesome_notifications/awesome_notifications.dart';
import '../../models/hymn.dart';
import 'notification_styles.dart';

class AudioPlayerNotificationBuilder {
  static const int notificationId = 1001;

  static String formatDuration(Duration? duration) {
    if (duration == null) return '';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static String buildNotificationBody(Hymn hymn, {Duration? position, Duration? duration}) {
    String body = 'Hira faha ${hymn.hymnNumber}';
    
    if (position != null && duration != null) {
      final positionText = formatDuration(position);
      final durationText = formatDuration(duration);
      body += ' • $positionText / $durationText';
    }
    
    return body;
  }

  static double? calculateProgress(Duration? position, Duration? duration) {
    if (position != null && duration != null && duration.inMilliseconds > 0) {
      final progress = (position.inMilliseconds.toDouble() / duration.inMilliseconds.toDouble()) * 100;
      return progress.clamp(0.0, 100.0);
    }
    return null;
  }

  static Future<void> showNotification({
    required Hymn hymn,
    required bool isPlaying,
    Duration? position,
    Duration? duration,
    required bool canGoNext,
    required bool canGoPrevious,
  }) async {
    final body = buildNotificationBody(hymn, position: position, duration: duration);
    final progress = calculateProgress(position, duration);
    final actionButtons = NotificationButtons.createAudioPlayerButtons(
      isPlaying: isPlaying,
      canGoNext: canGoNext,
      canGoPrevious: canGoPrevious,
    );

    final content = NotificationLayouts.createMediaPlayerNotification(
      id: notificationId,
      title: hymn.title,
      body: body,
      progress: progress,
      locked: isPlaying,
      autoDismissible: !isPlaying,
    );

    await AwesomeNotifications().createNotification(
      content: content,
      actionButtons: actionButtons,
    );
  }

  static Future<void> updateNotification({
    required Hymn hymn,
    required bool isPlaying,
    Duration? position,
    Duration? duration,
    required bool canGoNext,
    required bool canGoPrevious,
  }) async {
    await showNotification(
      hymn: hymn,
      isPlaying: isPlaying,
      position: position,
      duration: duration,
      canGoNext: canGoNext,
      canGoPrevious: canGoPrevious,
    );
  }

  static Future<void> hideNotification() async {
    try {
      await AwesomeNotifications().dismiss(notificationId);
      await AwesomeNotifications().cancelAll();
    } catch (e) {
      // Silently handle errors
    }
  }

  static Future<void> forceClearAllNotifications() async {
    try {
      await AwesomeNotifications().cancelAll();
    } catch (e) {
      // Silently handle errors
    }
  }
}