import 'package:fihirana/controller/auth_controller.dart';
import 'package:fihirana/controller/color_controller.dart';
import 'package:fihirana/controller/daily_verse_controller.dart';
import 'package:fihirana/controller/font_controller.dart';
import 'package:fihirana/controller/history_controller.dart';
import 'package:fihirana/controller/language_controller.dart';
import 'package:fihirana/controller/playlist_controller.dart';
import 'package:fihirana/controller/theme_controller.dart';
import 'package:fihirana/controller/shell_controller.dart';
import 'package:fihirana/controller/recording_controller.dart';
import 'package:fihirana/services/audio_file_mapping.dart';
import 'package:fihirana/services/audio_foreground_service.dart';
import 'package:fihirana/services/background_service.dart';
import 'package:fihirana/services/bible_service.dart';
import 'package:fihirana/services/firebase_sync_service.dart';
import 'package:fihirana/services/hymn_service.dart';
import 'package:fihirana/services/local_audio_service.dart';
import 'package:fihirana/services/notification_service.dart';
import 'package:fihirana/services/deep_link_service.dart';
import 'package:fihirana/services/version_check_service.dart';
import 'package:fihirana/services/security_service.dart';
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

    // Setup listeners for notification actions (e.g., audio player controls)
    NotificationService.setupNotificationListeners();
  }

  static Future<void> initControllers() async {
    // Initialize critical controllers first (needed for UI)
    final themeController = Get.put(ThemeController());
    final colorController = Get.put(ColorController());
    final fontController = Get.put(FontController());
    Get.put(LanguageController());
    Get.put(ShellController());

    // Load theme and colors (fast, from local storage)
    await colorController.loadColors();
    await themeController.loadThemeFromPrefs();

    // Initialize custom fonts before app starts using them
    await fontController.initializeCustomFonts();

    // Initialize other controllers (these are fast)
    Get.put(HistoryController());
    Get.put(AuthController());
    Get.put(DailyVerseController());
    Get.put(HymnService());
    Get.put(BackgroundService());
    Get.put(FirebaseSyncService());
    Get.put(FirebaseSyncService());
    Get.put(AudioForegroundService());
    Get.put(PlaylistController());
    Get.put(RecordingController());

    // Initialize security service (critical - runs on app startup)
    Get.put(SecurityService());

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
        // Check for updates on startup (silent check)
        await VersionCheckService.checkForUpdateOnStartup();

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

  static Future<void> initDeepLinks() async {
    try {
      final deepLinkService = DeepLinkService();
      await deepLinkService.init();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing deep links: $e');
      }
    }
  }
}
