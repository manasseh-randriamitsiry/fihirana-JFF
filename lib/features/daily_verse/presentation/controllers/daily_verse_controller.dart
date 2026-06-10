import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/daily_verse/domain/entities/daily_verse.dart';
import 'package:fihirana/features/daily_verse/domain/usecases/get_verse_of_the_day_usecase.dart';
import 'package:fihirana/features/daily_verse/domain/usecases/load_daily_verse_settings_usecase.dart';
import 'package:fihirana/features/daily_verse/domain/usecases/save_daily_verse_settings_usecase.dart';
import 'package:fihirana/features/daily_verse/domain/usecases/toggle_daily_verse_usecase.dart';
import 'package:fihirana/features/daily_verse/domain/usecases/update_notification_time_usecase.dart';
import 'package:fihirana/features/daily_verse/domain/usecases/send_test_notification_usecase.dart';
import 'package:fihirana/core/error/error_handler.dart';

class DailyVerseController extends GetxController {
  final GetVerseOfTheDayUseCase _getVerseOfTheDayUseCase;
  final LoadDailyVerseSettingsUseCase _loadSettingsUseCase;
  final SaveDailyVerseSettingsUseCase _saveSettingsUseCase;
  final ToggleDailyVerseUseCase _toggleDailyVerseUseCase;
  final UpdateNotificationTimeUseCase _updateNotificationTimeUseCase;
  final SendTestNotificationUseCase _sendTestNotificationUseCase;

  DailyVerseController({
    required GetVerseOfTheDayUseCase getVerseOfTheDayUseCase,
    required LoadDailyVerseSettingsUseCase loadSettingsUseCase,
    required SaveDailyVerseSettingsUseCase saveSettingsUseCase,
    required ToggleDailyVerseUseCase toggleDailyVerseUseCase,
    required UpdateNotificationTimeUseCase updateNotificationTimeUseCase,
    required SendTestNotificationUseCase sendTestNotificationUseCase,
  })  : _getVerseOfTheDayUseCase = getVerseOfTheDayUseCase,
        _loadSettingsUseCase = loadSettingsUseCase,
        _saveSettingsUseCase = saveSettingsUseCase,
        _toggleDailyVerseUseCase = toggleDailyVerseUseCase,
        _updateNotificationTimeUseCase = updateNotificationTimeUseCase,
        _sendTestNotificationUseCase = sendTestNotificationUseCase;

  // Observable state
  final RxBool isEnabled = false.obs;
  final Rx<TimeOfDay> notificationTime =
      const TimeOfDay(hour: 7, minute: 0).obs;
  final Rx<DailyVerse?> todaysVerse = Rx<DailyVerse?>(null);
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
    loadTodaysVerse();
  }

  /// Load settings from SharedPreferences
  Future<void> loadSettings() async {
    final settings = await _loadSettingsUseCase();
    isEnabled.value = settings['isEnabled'] as bool;
    final hour = settings['hour'] as int;
    final minute = settings['minute'] as int;
    notificationTime.value = TimeOfDay(hour: hour, minute: minute);

    // If enabled, ensure notification is scheduled
    if (isEnabled.value) {
      await _updateNotificationTimeUseCase(hour, minute, true);
    }
  }

  /// Load today's verse
  Future<void> loadTodaysVerse() async {
    try {
      isLoading.value = true;
      todaysVerse.value = await _getVerseOfTheDayUseCase();
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorOccurred'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  /// Toggle daily verse feature
  Future<void> toggleDailyVerse(bool enabled) async {
    isEnabled.value = enabled;
    await _saveSettingsUseCase(
        enabled, notificationTime.value.hour, notificationTime.value.minute);
    await _toggleDailyVerseUseCase(
        enabled, notificationTime.value.hour, notificationTime.value.minute);
  }

  /// Update notification time
  Future<void> updateNotificationTime(TimeOfDay time) async {
    notificationTime.value = time;
    await _saveSettingsUseCase(isEnabled.value, time.hour, time.minute);
    await _updateNotificationTimeUseCase(
        time.hour, time.minute, isEnabled.value);
  }

  /// Send test notification
  Future<void> sendTestNotification() async {
    await _sendTestNotificationUseCase();
  }

  /// Refresh today's verse
  Future<void> refreshVerse() async {
    await loadTodaysVerse();
  }
}
