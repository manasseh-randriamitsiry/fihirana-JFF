import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:fihirana/core/security/security_service.dart';
import 'package:fihirana/shared/widgets/common/banned_page.dart';
import 'package:fihirana/core/localization/language_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';

/// Manages application security and user blocking
class AppSecurityManager {
  SecurityService? _securityService;
  LanguageController? _languageController;

  SecurityService get _getSecurityService {
    _securityService ??= Get.find<SecurityService>();
    return _securityService!;
  }

  LanguageController get _getLanguageController {
    _languageController ??= Get.find<LanguageController>();
    return _languageController!;
  }

  /// Check if user is blocked and return appropriate widget
  Widget? getSecurityWrapper(Widget child) {
    // If user is blocked, show banned page instead of normal app
    if (_getSecurityService.isSecurityChecked &&
        _getSecurityService.isUserBlocked) {
      return Obx(() {
        final currentLocale = _getLanguageController.currentLocale.value;
        // Include refresh counter to force rebuild when language changes
        _getLanguageController.refreshCounter.value;

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
            return _getLanguageController.currentLocale.value;
          },
          supportedLocales: _getLanguageController.supportedLocales,
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
