import 'package:fihirana/controller/auth_controller.dart';
import 'package:fihirana/controller/color_controller.dart';
import 'package:fihirana/controller/daily_verse_controller.dart';
import 'package:fihirana/controller/font_controller.dart';
import 'package:fihirana/controller/history_controller.dart';
import 'package:fihirana/controller/language_controller.dart';
import 'package:fihirana/controller/theme_controller.dart';
import 'package:fihirana/services/audio_file_mapping.dart';
import 'package:fihirana/services/audio_foreground_service.dart';
import 'package:fihirana/services/background_service.dart';
import 'package:fihirana/services/bible_service.dart';
import 'package:fihirana/services/firebase_sync_service.dart';
import 'package:fihirana/services/hymn_service.dart';
import 'package:fihirana/services/local_audio_service.dart';
import 'package:fihirana/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class InitService {
  static Future<void> initializeNotifications() async {
    await NotificationService.initializeNotificationChannels();

    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  static Future<void> initControllers() async {
    // Initialize critical controllers first (needed for UI)
    final themeController = Get.put(ThemeController());
    final colorController = Get.put(ColorController());
    Get.put(FontController());
    Get.put(LanguageController());

    // Load theme and colors (fast, from local storage)
    await colorController.loadColors();
    await themeController.loadThemeFromPrefs();

    // Initialize other controllers (these are fast)
    Get.put(HistoryController());
    Get.put(AuthController());
    Get.put(DailyVerseController());
    Get.put(HymnService());
    Get.put(BackgroundService());
    Get.put(FirebaseSyncService());
    Get.put(AudioForegroundService());

    // Initialize Bible service (but don't load data yet)
    Get.put(BibleService());

    // Initialize local audio service (fast, just setup)
    final localAudioService = LocalAudioService();
    await localAudioService.initialize();

    // Move slow tasks to background
    _initializeBackgroundTasks();
  }

  /// Initialize slow tasks in the background after app has loaded
  static void _initializeBackgroundTasks() {
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        // Update audio file mapping (GitHub API call - can be slow)
        final audioMapping = AudioFileMapping();
        await audioMapping.updateAudioFileMapping();

        // Initialize Bible service data (can be slow on first load)
        final bibleService = Get.find<BibleService>();
        await bibleService.initialize((message) {
          if (kDebugMode) {
            print('Bible service: $message');
          }
        });

        if (kDebugMode) {
          print('Background initialization complete');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error in background initialization: $e');
        }
      }
    });
  }
}
