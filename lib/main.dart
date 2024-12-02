import 'package:fihirana/screen/intro/splash_screen1.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'controller/theme_controller.dart';
import 'controller/font_controller.dart';
import 'controller/color_controller.dart';
import 'screen/accueil/home_screen.dart';
import 'screen/accueil/accueil_screen.dart';
import 'services/version_check_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Initialize notification action handler
  await AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Basic notifications',
        channelDescription: 'Notification channel for basic tests',
        defaultColor: const Color(0xFF9D50DD),
        ledColor: Colors.white,
      ),
    ],
    debug: true,
  );
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
  final FontController fontController = Get.put(FontController());
  final ColorController colorController = Get.put(ColorController());

  @override
  void initState() {
    super.initState();
    // Initialize notifications and check for updates after app is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await VersionCheckService.initializeNotifications();
      await VersionCheckService.checkForUpdate();
    });
  }

  ThemeData _getThemeWithFont(ThemeData baseTheme, String fontFamily) {
    final TextTheme textTheme = GoogleFonts.getTextTheme(fontFamily);
    return baseTheme.copyWith(
      textTheme: textTheme.apply(
        bodyColor: baseTheme.textTheme.bodyLarge?.color,
        displayColor: baseTheme.textTheme.displayLarge?.color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.put(ThemeController());
    themeController.isDarkMode.value = widget.prefs.getBool('isDarkMode') ?? false;
    
    final bool isFirstTime = widget.prefs.getBool('isFirstTime') ?? true;
    
    return Obx(() {
      final currentFont = fontController.currentFont.value;
      
      ThemeData baseTheme = themeController.isDarkMode.value 
          ? colorController.getDarkTheme()
          : colorController.getLightTheme();
          
      final themeWithFont = _getThemeWithFont(baseTheme, currentFont);

      return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: themeController.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
        theme: themeWithFont,
        darkTheme: themeWithFont,
        home: isFirstTime ? SplashScreen1() : const HomeScreen(),
        getPages: [
          GetPage(name: '/accueil', page: () => const AccueilScreen()),
          GetPage(name: '/home', page: () => const HomeScreen()),
        ],
      );
    });
  }
}
