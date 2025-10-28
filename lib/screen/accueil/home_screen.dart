import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controller/color_controller.dart';
import '../../controller/theme_controller.dart';
import '../../widgets/drawer_widget.dart';
import '../../widgets/update_checker_widget.dart'; // Import update checker widget
import 'accueil_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ColorController _colorController = Get.find();
  final ThemeController _themeController = Get.find();
  final zoomDrawerController = ZoomDrawerController();

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _notFirstTime();
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

  void _handleDrawerToggle() {
    zoomDrawerController.toggle?.call();
  }

  @override
  Widget build(BuildContext context) {
    return UpdateCheckerWidget(
      child: Obx(() => ZoomDrawer(
            controller: zoomDrawerController,
            style: DrawerStyle.defaultStyle,
            menuScreen: DrawerWidget(openDrawer: _handleDrawerToggle),
            mainScreen: AccueilScreen(openDrawer: _handleDrawerToggle),
            borderRadius: 24.0,
            showShadow: true,
            angle: -12.0,
            menuBackgroundColor: _colorController.drawerColor.value,
            slideWidth: MediaQuery.of(context).size.width * 0.85,
            mainScreenTapClose: true,
            openCurve: Curves.fastOutSlowIn,
            closeCurve: Curves.bounceIn,
          )),
    );
  }
}

class HomeController extends GetxController {
  var selectedIndex = 0.obs;
  final zoomDrawerController = ZoomDrawerController();

  void toggleDrawer() {
    zoomDrawerController.toggle?.call();
    update();
  }
}