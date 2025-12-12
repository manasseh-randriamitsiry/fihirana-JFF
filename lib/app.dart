import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/app/theme/font_controller.dart';
import 'package:fihirana/core/localization/language_controller.dart';
import 'package:fihirana/app/theme/theme_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/core/navigation/app_router.dart';
import 'package:fihirana/core/theme/app_theme_manager.dart';
import 'package:fihirana/core/lifecycle/app_lifecycle_manager.dart';
import 'package:fihirana/core/security/app_security_manager.dart';
import 'package:fihirana/core/security/security_service.dart';
import 'package:fihirana/core/navigation/shell_controller.dart';
import 'package:fihirana/shared/widgets/navigation/responsive_shell.dart';
import 'package:fihirana/core/utils/version_check_service.dart';
import 'package:fihirana/features/intro/di/intro_di.dart';
import 'package:fihirana/core/error/error_handler.dart';
import 'package:fihirana/core/localization/fallback_localization_delegate.dart';



class MyApp extends StatefulWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final AppLifecycleManager _lifecycleManager;
  late final AppSecurityManager _securityManager;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize managers
    _lifecycleManager = AppLifecycleManager();
    _securityManager = AppSecurityManager();

    // Initialize controllers
    _initializeControllers();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await VersionCheckService.initializeNotifications();
    });
  }

  void _initializeControllers() {
    // Initialize core controllers if not already present
    if (!Get.isRegistered<ColorController>()) Get.put(ColorController());
    if (!Get.isRegistered<ThemeController>()) Get.put(ThemeController());
    if (!Get.isRegistered<FontController>()) Get.put(FontController());
    if (!Get.isRegistered<LanguageController>()) Get.put(LanguageController());
    if (!Get.isRegistered<SecurityService>()) Get.put(SecurityService());

    // Initialize intro controllers
    IntroDI.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lifecycleManager.cleanupServices();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleManager.didChangeAppLifecycleState(state);
  }

  String _getInitialRoute() {
    final bool isFirstTime = widget.prefs.getBool('isFirstTime') ?? true;
    final bool hasAgreed = widget.prefs.getBool('has_agreed_to_terms') ?? false;
    final String? username = widget.prefs.getString('username');
    final bool hasSelectedLanguage =
        widget.prefs.getString('selected_language') != null;

    final bool shouldGoToHome = !isFirstTime &&
        hasAgreed &&
        (username?.isNotEmpty ?? false) &&
        hasSelectedLanguage;

    return shouldGoToHome ? '/home' : (isFirstTime ? '/splash' : '/loading');
  }

  void _initializeShellController(String initialRoute) {
    try {
      final shellController = Get.find<ShellController>();
      shellController.setDrawerEnabled(initialRoute == '/home');
      shellController.currentRoute.value = initialRoute;
    } catch (e) {
      // Controller might not be ready
    }
  }

  void _handleRoutingCallback(Routing? routing) {
    if (routing != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final shellController = Get.find<ShellController>();
        shellController.currentRoute.value = routing.current;

        // Disable drawer on splash and loading screens
        final disableDrawer = routing.current == '/splash' || routing.current == '/loading';
        shellController.setDrawerEnabled(!disableDrawer);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check for security wrapper first
    final securityWrapper = _securityManager.getSecurityWrapper(Container());
    if (securityWrapper != null) {
      return securityWrapper;
    }

    // Determine initial route based on user state
    final initialRoute = _getInitialRoute();

    // Set initial drawer state
    _initializeShellController(initialRoute);

    return Obx(() {
      final fontController = Get.find<FontController>();
      final themeController = Get.find<ThemeController>();
      final languageController = Get.find<LanguageController>();

      final currentFont = fontController.currentFont.value;
      final isDark = themeController.isDarkMode.value;
      final currentLocale = languageController.currentLocale.value;
      languageController.refreshCounter.value; // Force rebuild on language change

      final themeManager = AppThemeManager();
      final theme = isDark
          ? themeManager.getDarkTheme(currentFont)
          : themeManager.getLightTheme(currentFont);

      return ErrorHandler.withErrorBoundary(
        GetMaterialApp(
          debugShowCheckedModeBanner: false,
        locale: currentLocale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          // Add fallback delegates for 'mg' support in Material/Cupertino widgets
          FallbackMaterialLocalizationsDelegate(),
          FallbackCupertinoLocalizationsDelegate(),
        ],
        localeResolutionCallback: (locale, supportedLocales) {
          return languageController.currentLocale.value;
        },
        supportedLocales: languageController.supportedLocales,
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        theme: theme,
        darkTheme: theme,
        builder: (context, child) => ResponsiveShell(child: child!),
        initialRoute: initialRoute,
        routingCallback: _handleRoutingCallback,
        getPages: AppRouter.getPages(),
        ),
      );
    });
  }
}
