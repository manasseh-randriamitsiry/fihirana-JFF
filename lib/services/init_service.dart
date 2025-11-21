import 'package:fihirana/controller/auth_controller.dart';
import 'package:fihirana/controller/color_controller.dart';
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
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class InitService {
  static Future<void> initializeNotifications() async {
    await NotificationService.initializeNotificationChannels();

    await AwesomeNotifications().initialize(
      'resource://mipmap/ic_launcher',
      [
        NotificationChannel(
          channelKey: 'announcement_channel',
          channelName: 'Filazana',
          channelDescription: 'Notifications for announcements',
          defaultColor: const Color(0xFF9D50DD),
          importance: NotificationImportance.High,
          channelShowBadge: true,
          enableVibration: true,
          enableLights: true,
          defaultPrivacy: NotificationPrivacy.Public,
          playSound: true,
          icon: 'resource://mipmap/ic_launcher',
        ),
        NotificationChannel(
          channelKey: 'hymn_download_channel',
          channelName: 'Maka Hira',
          channelDescription: 'Notifications for hymn downloads and updates',
          defaultColor: const Color(0xFF9D50DD),
          importance: NotificationImportance.High,
          channelShowBadge: true,
          icon: 'resource://mipmap/ic_launcher',
        ),
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic Notifications',
          channelDescription: 'Basic notifications channel',
          defaultColor: const Color(0xFF9D50DD),
          importance: NotificationImportance.High,
          channelShowBadge: true,
          icon: 'resource://mipmap/ic_launcher',
        ),
      ],
      debug: true,
    );

    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  static Future<void> initControllers() async {
    final themeController = Get.put(ThemeController());
    Get.put(HistoryController());
    final colorController = Get.put(ColorController());
    Get.put(FontController());
    Get.put(AuthController());
    Get.put(LanguageController());
    Get.put(HymnService());
    Get.put(BackgroundService());
    Get.put(FirebaseSyncService());
    Get.put(AudioForegroundService());
    // Initialize Bible service
    Get.put(BibleService());

    // Initialize audio file mapping
    final audioMapping = AudioFileMapping();
    await audioMapping.updateAudioFileMapping();

    // Initialize local audio service
    final localAudioService = LocalAudioService();
    await localAudioService.initialize();

    await colorController.loadColors();
    await themeController.loadThemeFromPrefs();

    // Initialize Bible service
    final bibleService = Get.find<BibleService>();
    await bibleService.initialize();
  }
}
