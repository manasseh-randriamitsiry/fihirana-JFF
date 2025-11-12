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
      }
    } catch (e) {
      debugPrint('Error loading language: $e');
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