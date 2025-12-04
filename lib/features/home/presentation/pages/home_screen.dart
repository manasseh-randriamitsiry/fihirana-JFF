import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/features/settings/presentation/widgets/update_checker_widget.dart';
import 'package:fihirana/core/navigation/shell_controller.dart';
import 'accueil_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ColorController _colorController = Get.find();
  final zoomDrawerController = ZoomDrawerController();

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _notFirstTime();

    // Enable drawer when entering Home Screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<ShellController>().setDrawerEnabled(true);
    });
  }

  Future<void> _initializeApp() async {
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
            channelDescription: 'Filazana rehetra',
            defaultColor: _colorController.primaryColor.value,
            importance: NotificationImportance.High,
            enableVibration: true,
            enableLights: true,
          ),
        ],
        debug: true,
      );
      await prefs.setBool('notificationsInitialized', true);
    }
  }

  Future<void> _notFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
  }

  @override
  Widget build(BuildContext context) {
    return UpdateCheckerWidget(
      child: AccueilScreen(
        openDrawer: () {
          Get.find<ShellController>().toggleDrawer();
        },
        showMenuButton: true,
      ),
    );
  }
}

class HomeController extends GetxController {
  final RxInt selectedIndex = 0.obs;
  final zoomDrawerController = ZoomDrawerController();

  void toggleDrawer() {
    zoomDrawerController.toggle?.call();
    update();
  }
}
