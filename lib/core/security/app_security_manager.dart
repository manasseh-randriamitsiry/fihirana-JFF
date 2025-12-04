import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:fihirana/core/security/security_service.dart';
import 'package:fihirana/shared/widgets/common/banned_page.dart';
import 'package:fihirana/core/localization/language_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';

/// Manages application security and user blocking
class AppSecurityManager {
  final SecurityService _securityService = Get.find<SecurityService>();
  final LanguageController _languageController = Get.find<LanguageController>();

  /// Check if user is blocked and return appropriate widget
  Widget? getSecurityWrapper(Widget child) {
    // If user is blocked, show banned page instead of normal app
    if (_securityService.isSecurityChecked && _securityService.isUserBlocked) {
      return Obx(() {
        final currentLocale = _languageController.currentLocale.value;
        // Include refresh counter to force rebuild when language changes
        _languageController.refreshCounter.value;

        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          locale: currentLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (locale, supportedLocales) {
            return _languageController.currentLocale.value;
          },
          supportedLocales: _languageController.supportedLocales,
          themeMode: ThemeMode.system,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          home: const BannedPage(),
        );
      });
    }

    return null; // No security wrapper needed
  }
}

