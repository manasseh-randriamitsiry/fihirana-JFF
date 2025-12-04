import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:fihirana/app/theme/color_controller.dart';

/// Home controller for managing home screen logic
class HomeController extends GetxController {
  final ColorController _colorController = Get.find();

  final RxBool isInitialized = false.obs;

  @override
  void onInit() {
    super.onInit();
    initializeApp();
    markNotFirstTime();
  }

  /// Initialize app components
  Future<void> initializeApp() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('notificationsInitialized')) {
      await AwesomeNotifications().initialize(
        null,
        [
          NotificationChannel(
            channelKey: 'basic_channel',
            channelName: 'Basic Notifications',
            channelDescription: 'Basic notifications channel',
            defaultColor: _colorController.primaryColor.value,
            importance: NotificationImportance.High,
            channelShowBadge: true,
          ),
          NotificationChannel(
            channelKey: 'announcement_channel',
            channelName: 'Filazana',
            channelDescription: 'Announcement notifications',
            defaultColor: _colorController.primaryColor.value,
            importance: NotificationImportance.High,
            channelShowBadge: true,
          ),
          NotificationChannel(
            channelKey: 'daily_verse_channel',
            channelName: 'Andininy isan\'andro',
            channelDescription: 'Daily verse notifications',
            defaultColor: _colorController.primaryColor.value,
            importance: NotificationImportance.High,
            channelShowBadge: true,
          ),
        ],
      );
      await prefs.setBool('notificationsInitialized', true);
    }

    isInitialized.value = true;
  }

  /// Mark that user has opened the app before
  Future<void> markNotFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notFirstTime', true);
  }
}