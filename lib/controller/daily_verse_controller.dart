import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_verse.dart';
import '../services/features/daily_verse_service.dart';

class DailyVerseController extends GetxController {
  final DailyVerseService _dailyVerseService = DailyVerseService();

  // Observable state
  final RxBool isEnabled = false.obs;
  final Rx<TimeOfDay> notificationTime =
      const TimeOfDay(hour: 7, minute: 0).obs;
  final Rx<DailyVerse?> todaysVerse = Rx<DailyVerse?>(null);
  final RxBool isLoading = false.obs;

  static const String _enabledKey = 'daily_verse_enabled';
  static const String _hourKey = 'daily_verse_hour';
  static const String _minuteKey = 'daily_verse_minute';

  @override
  void onInit() {
    super.onInit();
    loadSettings();
    loadTodaysVerse();
  }

  /// Load settings from SharedPreferences
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    isEnabled.value = prefs.getBool(_enabledKey) ?? false;
    final hour = prefs.getInt(_hourKey) ?? 7;
    final minute = prefs.getInt(_minuteKey) ?? 0;
    notificationTime.value = TimeOfDay(hour: hour, minute: minute);

    // If enabled, ensure notification is scheduled
    if (isEnabled.value) {
      await _dailyVerseService.scheduleDailyNotification(hour, minute);
    }
  }

  /// Load today's verse
  Future<void> loadTodaysVerse() async {
    try {
      isLoading.value = true;
      todaysVerse.value = await _dailyVerseService.getVerseOfTheDay();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading today\'s verse: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Toggle daily verse feature
  Future<void> toggleDailyVerse(bool enabled) async {
    isEnabled.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);

    if (enabled) {
      // Schedule notification
      await _dailyVerseService.scheduleDailyNotification(
        notificationTime.value.hour,
        notificationTime.value.minute,
      );
    } else {
      // Cancel notifications
      await _dailyVerseService.cancelDailyNotifications();
    }
  }

  /// Update notification time
  Future<void> updateNotificationTime(TimeOfDay time) async {
    notificationTime.value = time;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hourKey, time.hour);
    await prefs.setInt(_minuteKey, time.minute);

    // Reschedule if enabled
    if (isEnabled.value) {
      await _dailyVerseService.scheduleDailyNotification(
        time.hour,
        time.minute,
      );
    }
  }

  /// Send test notification
  Future<void> sendTestNotification() async {
    await _dailyVerseService.sendTestNotification();
  }

  /// Refresh today's verse
  Future<void> refreshVerse() async {
    await loadTodaysVerse();
  }
}
