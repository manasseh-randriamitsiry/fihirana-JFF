import 'package:fihirana/features/daily_verse/domain/entities/daily_verse.dart';

abstract class IDailyVerseService {
  Future<DailyVerse> getVerseOfTheDay();
  Future<void> scheduleDailyNotification(int hour, int minute);
  Future<void> cancelDailyNotifications();
  Future<void> sendTestNotification();
}