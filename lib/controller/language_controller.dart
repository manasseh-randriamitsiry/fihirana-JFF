import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';



class LanguageController extends GetxController {
  static const String _languageKey = 'selected_language';

  final Rx<Locale> currentLocale = const Locale('mg').obs;

  // Add a refresh counter to force app rebuilds
  final RxInt refreshCounter = 0.obs;

  // Supported locales (only ones we have translations for)
  final RxList<Locale> supportedLocales = <Locale>[
    const Locale('mg'), // Malagasy
    const Locale('en'), // English
    const Locale('fr'), // French
  ].obs;

  @override
  void onInit() {
    super.onInit();
    _loadLanguage();
    _loadAllSupportedLanguages();
  }

  Future<void> _loadAllSupportedLanguages() async {
    // Only use natively supported locales
    supportedLocales.sort((a, b) {
      final nameA = getLanguageName(a);
      final nameB = getLanguageName(b);
      return nameA.compareTo(nameB);
    });
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey);

      debugPrint('Loading language from prefs: $languageCode');

      if (languageCode != null) {
        final locale = Locale(languageCode);
        // We accept any locale now, as we support many languages
        currentLocale.value = locale;
        debugPrint('Setting currentLocale to: ${locale.languageCode}');
        // Also update GetX locale when loading
        await Get.updateLocale(locale);
        debugPrint('Updated GetX locale to: ${locale.languageCode}');
      } else {
        // Auto-detect system language if no language is saved
        debugPrint('No saved language, detecting system language');
        _detectSystemLanguage();
      }
    } catch (e) {
      debugPrint('Error loading language: $e');
      // Fallback to Malagasy if there's an error
      currentLocale.value = const Locale('mg');
      await Get.updateLocale(const Locale('mg'));
    }
  }

  void _detectSystemLanguage() {
    try {
      final systemLocale = Get.deviceLocale ?? const Locale('mg');
      // Use system locale directly if possible, otherwise fallback
      currentLocale.value = systemLocale;

      // Save the detected language
      _saveLanguage(systemLocale.languageCode);
      // Also update GetX locale
      Get.updateLocale(systemLocale);
    } catch (e) {
      debugPrint('Error detecting system language: $e');
      // Fallback to Malagasy
      currentLocale.value = const Locale('mg');
      Get.updateLocale(const Locale('mg'));
    }
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
