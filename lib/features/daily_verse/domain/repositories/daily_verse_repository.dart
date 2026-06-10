import 'package:fihirana/features/daily_verse/domain/entities/daily_verse.dart';

/// Repository interface for daily verse operations
abstract class DailyVerseRepository {
  /// Get the verse of the day
  Future<DailyVerse> getVerseOfTheDay();

  /// Schedule daily notification at specified time
  Future<void> scheduleDailyNotification(int hour, int minute);

  /// Cancel all daily verse notifications
  Future<void> cancelDailyNotifications();

  /// Send test notification immediately
  Future<void> sendTestNotification();

  /// Load settings from SharedPreferences
  Future<Map<String, dynamic>> loadSettings();

  /// Save settings to SharedPreferences
  Future<void> saveSettings(bool isEnabled, int hour, int minute);
}
