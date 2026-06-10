import 'package:fihirana/features/daily_verse/domain/repositories/daily_verse_repository.dart';
import 'package:fihirana/features/daily_verse/domain/entities/daily_verse.dart';
import 'package:fihirana/features/daily_verse/data/services/daily_verse_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Implementation of DailyVerseRepository
class DailyVerseRepositoryImpl implements DailyVerseRepository {
  final DailyVerseService _dailyVerseService;

  DailyVerseRepositoryImpl(this._dailyVerseService);

  static const String _enabledKey = 'daily_verse_enabled';
  static const String _hourKey = 'daily_verse_hour';
  static const String _minuteKey = 'daily_verse_minute';

  @override
  Future<DailyVerse> getVerseOfTheDay() async {
    return await _dailyVerseService.getVerseOfTheDay();
  }

  @override
  Future<void> scheduleDailyNotification(int hour, int minute) async {
    return await _dailyVerseService.scheduleDailyNotification(hour, minute);
  }

  @override
  Future<void> cancelDailyNotifications() async {
    return await _dailyVerseService.cancelDailyNotifications();
  }

  @override
  Future<void> sendTestNotification() async {
    return await _dailyVerseService.sendTestNotification();
  }

  @override
  Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_enabledKey) ?? false;
    final hour = prefs.getInt(_hourKey) ?? 7;
    final minute = prefs.getInt(_minuteKey) ?? 0;

    return {
      'isEnabled': isEnabled,
      'hour': hour,
      'minute': minute,
    };
  }

  @override
  Future<void> saveSettings(bool isEnabled, int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, isEnabled);
    await prefs.setInt(_hourKey, hour);
    await prefs.setInt(_minuteKey, minute);
  }
}
