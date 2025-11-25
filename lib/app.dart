import 'package:fihirana/controller/color_controller.dart';
import 'package:fihirana/controller/font_controller.dart';
import 'package:fihirana/controller/language_controller.dart';
import 'package:fihirana/controller/theme_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/screen/accueil/home_screen.dart';
import 'package:fihirana/widgets/responsive_shell.dart';
import 'package:fihirana/controller/shell_controller.dart';
import 'package:fihirana/screen/intro/splash_screen1.dart';
import 'package:fihirana/screen/loading/loading_screen.dart';
import 'package:fihirana/services/version_check_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fihirana/screen/bible/bible_reader_screen.dart';
import 'package:fihirana/screen/favorite/favorites_screen.dart';
import 'package:fihirana/screen/admin/admin_panel_screen.dart';
import 'package:fihirana/screen/about/about_screen.dart';
import 'package:fihirana/screen/history/history_screen.dart';
import 'package:fihirana/screen/announcement/announcement_screen.dart';
import 'package:fihirana/screen/hymn/create_hymn_page.dart';
import 'package:fihirana/screen/hymn/firebase_hymns_screen.dart';
import 'package:fihirana/screen/playlist/playlist_list_screen.dart';
import 'package:fihirana/screen/settings/daily_verse_settings_screen.dart';
import 'package:fihirana/screen/settings/settings_screen.dart';
import 'package:fihirana/screen/recording/recording_manager_screen.dart';
import 'package:fihirana/services/security_service.dart';

// ... existing imports

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

    final initialRoute =
        shouldGoToHome ? '/home' : (isFirstTime ? '/splash' : '/loading');

    // Set initial drawer state
    try {
      final shellController = Get.find<ShellController>();
      shellController.setDrawerEnabled(initialRoute == '/home');
      shellController.currentRoute.value = initialRoute;
    } catch (e) {
      // Controller might not be ready if InitService failed, but it should be
    }

    return Obx(() {
      final currentFont = fontController.currentFont.value;
      final isDark = themeController.isDarkMode.value;
      final currentLocale = languageController.currentLocale.value;

      // Check if user is blocked before building the app
      final SecurityService securityService = Get.find<SecurityService>();
      
      // If user is blocked, show banned page instead of normal app
      if (securityService.isSecurityChecked && securityService.isUserBlocked) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          locale: currentLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            _FallbackMaterialLocalizationsDelegate(),
            _FallbackCupertinoLocalizationsDelegate(),
          ],
          supportedLocales: const [
            Locale('mg'), // Malagasy
            Locale('en'), // English
            Locale('fr'), // French
          ],
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: _getThemeWithFont(
              isDark ? colorController.getDarkTheme() : colorController.getLightTheme(),
              currentFont),
          darkTheme: _getThemeWithFont(
              isDark ? colorController.getDarkTheme() : colorController.getLightTheme(),
              currentFont),
          home: const BannedPage(),
          builder: (context, child) => ResponsiveShell(child: child!),
        );
      }

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
        builder: (context, child) {
          return ResponsiveShell(child: child!);
        },
        initialRoute: initialRoute,
        routingCallback: (routing) {
          if (routing != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final shellController = Get.find<ShellController>();
              shellController.currentRoute.value = routing.current;

              // Disable drawer on splash and loading screens
              if (routing.current == '/splash' ||
                  routing.current == '/loading') {
                shellController.setDrawerEnabled(false);
              } else {
                shellController.setDrawerEnabled(true);
              }
            });
          }
        },
        getPages: [
          GetPage(name: '/splash', page: () => const SplashScreen1()),
          GetPage(name: '/loading', page: () => const LoadingScreen()),
          GetPage(name: '/home', page: () => const HomeScreen()),
          GetPage(name: '/create_hymn', page: () => const CreateHymnPage()),
          GetPage(
              name: '/firebase_hymns', page: () => const FirebaseHymnsScreen()),
          GetPage(name: '/bible', page: () => const BibleReaderScreen()),
          GetPage(name: '/favorites', page: () => const FavoritesPage()),
          GetPage(name: '/history', page: () => HistoryScreen()),
          GetPage(name: '/playlists', page: () => const PlaylistListScreen()),
          GetPage(
              name: '/recordings', page: () => const RecordingManagerScreen()),
          GetPage(
              name: '/daily_verse_settings',
              page: () => DailyVerseSettingsScreen()),
          GetPage(name: '/settings', page: () => const SettingsScreen()),
          GetPage(
              name: '/announcements', page: () => const AnnouncementScreen()),
          GetPage(name: '/admin', page: () => const AdminPanelScreen()),
          GetPage(name: '/about', page: () => const AboutScreen()),
        ],
      );
    });
  }
}
