import 'package:fihirana/services/hymn_service.dart';
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
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'screen/announcement/announcement_screen.dart';
import 'services/background_service.dart';
// Added import for in_app_update
// Import the update dialog
import 'services/firebase_sync_service.dart'; // Add Firebase sync service

Future<void> initializeNotifications() async {
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

  // Request notification permissions
  await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    if (!isAllowed) {
      AwesomeNotifications().requestPermissionToSendNotifications();
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize notifications
  await initializeNotifications();

  final prefs = await SharedPreferences.getInstance();

  // Initialize controllers and services
  final themeController = Get.put(ThemeController());
  Get.put(HistoryController());
  Get.put(ColorController());
  Get.put(FontController());
  Get.lazyPut(() => HymnService());
  Get.put(BackgroundService());
  Get.put(FirebaseSyncService()); // Initialize Firebase sync service

  // Initialize theme from preferences
  themeController.isDarkMode.value = prefs.getBool('isDarkMode') ?? false;

  // Initialize notification action listener
  AwesomeNotifications().setListeners(
    onActionReceivedMethod: (ReceivedAction receivedAction) async {
      if (receivedAction.channelKey == 'announcement_channel' && 
          receivedAction.buttonKeyPressed == 'OPEN') {
        String? announcementId = receivedAction.payload?['announcementId'];
        if (announcementId != null) {
          Get.to(() => const AnnouncementScreen());
        }
      }
    },
  );

  runApp(
    Phoenix(
      child: MyApp(prefs: prefs),
    ),
  );
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Check if flexible update is available when app resumes
    if (state == AppLifecycleState.resumed) {
      // The app has resumed, check if we need to complete a flexible update
      // This would be handled by the VersionCheckService
    }
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
          GetPage(name: '/splash', page: () => const SplashScreen1()),
          GetPage(name: '/loading', page: () => const LoadingScreen()),
          GetPage(name: '/home', page: () => const HomeScreen()),
        ],
      );
    });
  }
}