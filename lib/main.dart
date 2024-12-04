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
    // Initialize theme from preferences
    themeController.isDarkMode.value =
        widget.prefs.getBool('isDarkMode') ?? false;
    final bool isFirstTime = widget.prefs.getBool('isFirstTime') ?? true;

    return Obx(() {
      final currentFont = fontController.currentFont.value;
      final isDark = themeController.isDarkMode.value;

      // Get the appropriate base theme
      ThemeData baseTheme = isDark
          ? colorController.getDarkTheme()
          : colorController.getLightTheme();

      // Apply font to the theme
      final themeWithFont = _getThemeWithFont(baseTheme, currentFont);

      return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        theme: themeWithFont,
        darkTheme: themeWithFont,
        home: isFirstTime ? SplashScreen1() : const HomeScreen(),
        initialRoute: isFirstTime ? '/splash' : '/home',
        getPages: [
          GetPage(name: '/splash', page: () => SplashScreen1()),
          GetPage(name: '/home', page: () => const HomeScreen()),
        ],
      );
    });
  }
}
