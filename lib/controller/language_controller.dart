import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';

class LanguageController extends GetxController {
  static const String _languageKey = 'selected_language';

  final Rx<Locale> currentLocale = const Locale('mg').obs;

  final List<Locale> supportedLocales = [
    const Locale('mg'), // Malagasy
    const Locale('en'), // English
    const Locale('fr'), // French
  ];

  @override
  void onInit() {
    super.onInit();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey);

      if (languageCode != null) {
        final locale = Locale(languageCode);
        if (supportedLocales.contains(locale)) {
          currentLocale.value = locale;
        }
      } else {
        // Auto-detect system language if no language is saved
        _detectSystemLanguage();
      }
    } catch (e) {
      debugPrint('Error loading language: $e');
      // Fallback to Malagasy if there's an error
      currentLocale.value = const Locale('mg');
    }
  }

  void _detectSystemLanguage() {
    try {
      final systemLocale = Get.deviceLocale ?? const Locale('mg');
      final supportedLocale = _findSupportedLocale(systemLocale);
      currentLocale.value = supportedLocale;

      // Save the detected language
      _saveLanguage(supportedLocale.languageCode);
    } catch (e) {
      debugPrint('Error detecting system language: $e');
      // Fallback to Malagasy
      currentLocale.value = const Locale('mg');
    }
  }

  Locale _findSupportedLocale(Locale systemLocale) {
    // Check if the exact locale is supported
    if (supportedLocales.contains(systemLocale)) {
      return systemLocale;
    }

    // Check if a locale with the same language code is supported
    for (final locale in supportedLocales) {
      if (locale.languageCode == systemLocale.languageCode) {
        return locale;
      }
    }

    // Fallback to Malagasy
    return const Locale('mg');
  }

  Future<void> _saveLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
    } catch (e) {
      debugPrint('Error saving language: $e');
    }
  }

  Future<void> changeLanguage(Locale locale) async {
    try {
      if (!supportedLocales.contains(locale)) {
        debugPrint('Unsupported locale: $locale');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, locale.languageCode);
      currentLocale.value = locale;

      // Update GetX locale
      Get.updateLocale(locale);

      debugPrint('Language changed to: ${locale.languageCode}');
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
