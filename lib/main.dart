import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'controller/theme_controller.dart';
import 'controller/font_controller.dart';
import 'controller/color_controller.dart';
import 'screen/accueil/home_screen.dart';
import 'screen/intro/splash_screen1.dart';
import 'services/version_check_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatefulWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final FontController fontController;
  late final ColorController colorController;
  late final ThemeController themeController;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    colorController = Get.put(ColorController());
    themeController = Get.put(ThemeController());
    fontController = Get.put(FontController());

    // Initialize notifications and check for updates
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await VersionCheckService.initializeNotifications();
      await VersionCheckService.checkForUpdate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: colorController.getLightTheme(),
      darkTheme: colorController.getDarkTheme(),
      themeMode: themeController.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
      home: const HomeScreen(),
      initialRoute: '/home',
      getPages: [
        GetPage(name: '/home', page: () => const HomeScreen()),
      ],
    );
  }
}
