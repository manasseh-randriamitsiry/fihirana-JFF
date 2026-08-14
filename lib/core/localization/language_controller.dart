import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fihirana/l10n/app_localizations.dart';

class LanguageController extends GetxController {
  static const String _languageKey = 'selected_language';

  final Rx<Locale> currentLocale = const Locale('fr').obs;

  // Add a refresh counter to force app rebuilds
  final RxInt refreshCounter = 0.obs;

  // Supported locales (only ones we have translations for)
  final RxList<Locale> supportedLocales = <Locale>[
    const Locale('fr'), // French
    const Locale('mg'), // Malagasy
    const Locale('en'), // English
  ].obs;

  Future<void> changeLanguage(Locale locale) async {
    try {
      debugPrint('Changing language to: ${locale.languageCode}');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, locale.languageCode);
      debugPrint('Saved language to prefs: ${locale.languageCode}');

      currentLocale.value = locale;
      debugPrint('Set currentLocale to: ${locale.languageCode}');

      // Update GetX locale - this should trigger a rebuild of the app
      await Get.updateLocale(locale);
      debugPrint('Updated GetX locale to: ${locale.languageCode}');

      // Force app rebuild by incrementing refresh counter
      refreshCounter.value++;
      debugPrint('Incremented refresh counter to force rebuild');

      debugPrint('Language successfully changed to: ${locale.languageCode}');
    } catch (e) {
      debugPrint('Error changing language: $e');
    }
  }

  String getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'mg':
        return 'Malagasy';
      case 'en':
        return 'English';
      case 'fr':
        return 'Français';
      default:
        // Fallback to uppercase code if not found
        return locale.languageCode.toUpperCase();
    }
  }

  String getLanguageFlag(Locale locale) {
    switch (locale.languageCode) {
      case 'mg':
        return '🇲🇬';
      case 'en':
        return '🇬🇧';
      case 'fr':
        return '🇫🇷';
      default:
        return '🌐';
    }
  }

  Locale get currentLocaleValue => currentLocale.value;

  bool isCurrentLocale(Locale locale) {
    return currentLocale.value.languageCode == locale.languageCode;
  }

  AppLocalizations? get translations {
    final context = Get.context;
    if (context != null) {
      return AppLocalizations.of(context);
    }
    // Return null when context is not available
    return null;
  }
}
