import 'package:fihirana/controller/color_controller.dart';
import 'package:fihirana/controller/font_controller.dart';
import 'package:fihirana/controller/language_controller.dart';
import 'package:fihirana/controller/theme_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/screen/accueil/home_screen.dart';
import 'package:fihirana/screen/intro/splash_screen1.dart';
import 'package:fihirana/screen/loading/loading_screen.dart';
import 'package:fihirana/services/version_check_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'package:shared_preferences/shared_preferences.dart';

// Fallback localization delegate for unsupported locales
class _FallbackMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _FallbackMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Support all locales to prevent warnings
    return true;
  }

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    // For unsupported locales, fall back to English Material localizations
    // Use proper way to load Material localizations
    return await GlobalMaterialLocalizations.delegate.load(const Locale('en'));
  }

  @override
  bool shouldReload(LocalizationsDelegate<MaterialLocalizations> old) => false;
}

// Fallback Cupertino localization delegate for unsupported locales
class _FallbackCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _FallbackCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Support all locales to prevent warnings
    return true;
  }

  @override
  Future<CupertinoLocalizations> load(Locale locale) async {
    // For unsupported locales, fall back to English Cupertino localizations
    return await GlobalCupertinoLocalizations.delegate.load(const Locale('en'));
  }

  @override
  bool shouldReload(LocalizationsDelegate<CupertinoLocalizations> old) => false;
}

class MyApp extends StatefulWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final FontController fontController;
  late final ColorController colorController;
  late final ThemeController themeController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    colorController = Get.find<ColorController>();
    themeController = Get.find<ThemeController>();
    fontController = Get.find<FontController>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await VersionCheckService.initializeNotifications();
      // Don't check for updates on startup - let the UpdateCheckerWidget handle it
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {}
  }

  ThemeData _getThemeWithFont(ThemeData baseTheme, String fontName) {
    // Check if it's a custom font first
    String fontFamily;
    if (fontController.customFonts.contains(fontName)) {
      // For custom fonts, use the font name directly as the family name
      fontFamily = fontName;
    } else {
      // For predefined fonts, get from the map or default to 'Lato'
      fontFamily = fontController.fontMap[fontName] ?? 'Lato';
    }

    return baseTheme.copyWith(
      textTheme: baseTheme.textTheme.apply(fontFamily: fontFamily),
      primaryTextTheme:
          baseTheme.primaryTextTheme.apply(fontFamily: fontFamily),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isFirstTime = widget.prefs.getBool('isFirstTime') ?? true;
    final bool hasAgreed = widget.prefs.getBool('has_agreed_to_terms') ?? false;
    final String? username = widget.prefs.getString('username');
    final bool hasSelectedLanguage =
        widget.prefs.getString('selected_language') != null;

    // If user has completed onboarding, go directly to home screen
    final bool shouldGoToHome = !isFirstTime &&
        hasAgreed &&
        (username?.isNotEmpty ?? false) &&
        hasSelectedLanguage;

    final LanguageController languageController =
        Get.find<LanguageController>();

    return Obx(() {
      final currentFont = fontController.currentFont.value;
      final isDark = themeController.isDarkMode.value;
      final currentLocale = languageController.currentLocale.value;

      ThemeData baseTheme = isDark
          ? colorController.getDarkTheme()
          : colorController.getLightTheme();

      final themeWithFont = _getThemeWithFont(baseTheme, currentFont);

      return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        locale: currentLocale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          // Add fallback delegates for unsupported locales
          _FallbackMaterialLocalizationsDelegate(),
          _FallbackCupertinoLocalizationsDelegate(),
        ],
        supportedLocales: const [
          Locale('mg'), // Malagasy
          Locale('en'), // English
          Locale('fr'), // French
        ],
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        theme: themeWithFont,
        darkTheme: themeWithFont,
        initialRoute:
            shouldGoToHome ? '/home' : (isFirstTime ? '/splash' : '/loading'),
        getPages: [
          GetPage(name: '/splash', page: () => const SplashScreen1()),
          GetPage(name: '/loading', page: () => const LoadingScreen()),
          GetPage(name: '/home', page: () => const HomeScreen()),
        ],
      );
    });
  }
}
