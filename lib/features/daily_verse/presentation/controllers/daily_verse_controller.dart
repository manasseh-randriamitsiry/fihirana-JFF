import 'dart:async';

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
import 'package:fihirana/core/utils/notification_reliability.dart';

class DailyVerseController extends GetxController with WidgetsBindingObserver {
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
  final RxBool isEnabled = true.obs;
  final Rx<TimeOfDay> notificationTime =
      const TimeOfDay(hour: 7, minute: 0).obs;
  final Rx<DailyVerse?> todaysVerse = Rx<DailyVerse?>(null);
  final RxBool isLoading = false.obs;

  /// True when the system is free to delay or drop the scheduled verse.
  final RxBool deliveryAtRisk = false.obs;

  final NotificationReliability _reliability = NotificationReliability();

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    loadSettings();
    loadTodaysVerse();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// The two settings that need a screen - exact alarms and battery
  /// optimisation - come back answered or not, and the system does not notify
  /// the app either way. Coming back to the foreground is the only signal.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(refreshDeliveryRisk());
    }
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
    await refreshDeliveryRisk();
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
    await refreshDeliveryRisk();
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

  /// Whether the system is currently free to delay or drop the scheduled verse.
  Future<void> refreshDeliveryRisk() async {
    if (!isEnabled.value) {
      deliveryAtRisk.value = false;
      return;
    }
    deliveryAtRisk.value = await _reliability.isAtRisk;
  }

  /// Opens the prompt or screen for whichever setting blocks delivery. Only a
  /// notification permission can be verified straight away; a settings page
  /// comes back before the user has decided, so its blocker is re-read on the
  /// next resume. When a fix did land, the alarm is re-created - a schedule
  /// registered while the exact-alarm permission was missing is not upgraded by
  /// the permission alone.
  Future<void> resolveDeliveryRisk() async {
    final blocker = await _reliability.blocker;
    if (blocker == DeliveryBlocker.none) {
      deliveryAtRisk.value = false;
      return;
    }
    final cleared = await _reliability.resolve(blocker);
    if (cleared && isEnabled.value) {
      final time = notificationTime.value;
      await _updateNotificationTimeUseCase(time.hour, time.minute, true);
    }
    await refreshDeliveryRisk();
  }

  /// Refresh today's verse
  Future<void> refreshVerse() async {
    await loadTodaysVerse();
  }
}
