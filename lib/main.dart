import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'controller/history_controller.dart';
import 'controller/theme_controller.dart';
import 'controller/font_controller.dart';
import 'controller/color_controller.dart';
import 'screen/accueil/home_screen.dart';
import 'screen/intro/splash_screen1.dart';
import 'screen/loading/loading_screen.dart';
import 'services/version_check_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with correct options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();

  // Initialize controllers once
  final themeController = Get.put(ThemeController());
  Get.put(HistoryController());
  Get.put(ColorController());
  Get.put(FontController());

  // Initialize theme from preferences
  themeController.isDarkMode.value = prefs.getBool('isDarkMode') ?? false;

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

    // Get existing controller instances
    colorController = Get.find<ColorController>();
    themeController = Get.find<ThemeController>();
    fontController = Get.find<FontController>();

    // Initialize notifications and check for updates
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await VersionCheckService.initializeNotifications();
      await VersionCheckService.checkForUpdate();
    });
  }

  ThemeData _getThemeWithFont(ThemeData baseTheme, String fontFamily) {
    // Create a complete text theme with all necessary styles
    final TextTheme textTheme = TextTheme(
      displayLarge: GoogleFonts.getFont(
        fontFamily,
        textStyle: baseTheme.textTheme.displayLarge?.copyWith(
          fontSize: 57.0,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
          height: 1.12,
        ),
      ),
      displayMedium: GoogleFonts.getFont(
        fontFamily,
        textStyle: baseTheme.textTheme.displayMedium?.copyWith(
          fontSize: 45.0,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
          height: 1.16,
        ),
      ),
      displaySmall: GoogleFonts.getFont(
        fontFamily,
        textStyle: baseTheme.textTheme.displaySmall?.copyWith(
          fontSize: 36.0,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
          height: 1.22,
        ),
      ),
      bodyLarge: GoogleFonts.getFont(
        fontFamily,
        textStyle: baseTheme.textTheme.bodyLarge?.copyWith(
          fontSize: 16.0,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          height: 1.5,
        ),
      ),
      bodyMedium: GoogleFonts.getFont(
        fontFamily,
        textStyle: baseTheme.textTheme.bodyMedium?.copyWith(
          fontSize: 14.0,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          height: 1.43,
        ),
      ),
      titleLarge: GoogleFonts.getFont(
        fontFamily,
        textStyle: baseTheme.textTheme.titleLarge?.copyWith(
          fontSize: 22.0,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          height: 1.27,
        ),
      ),
    );

    return baseTheme.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
    );
  }

  @override
  Widget build(BuildContext context) {
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
        initialRoute: isFirstTime ? '/splash' : '/loading',
        getPages: [
          GetPage(name: '/splash', page: () => SplashScreen1()),
          GetPage(name: '/loading', page: () => const LoadingScreen()),
          GetPage(name: '/home', page: () => const HomeScreen()),
        ],
      );
    });
  }
}
