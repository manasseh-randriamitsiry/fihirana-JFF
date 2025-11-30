import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';

import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class LanguageController extends GetxController {
  static const String _languageKey = 'selected_language';

  final Rx<Locale> currentLocale = const Locale('mg').obs;

  // Add a refresh counter to force app rebuilds
  final RxInt refreshCounter = 0.obs;

  // Start with default supported locales (only ones we have translations for)
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
    // Start with Malagasy as it's our primary language
    final Set<String> uniqueLanguageCodes = {'mg'};

    // Add all ML Kit supported languages
    for (final language in TranslateLanguage.values) {
      uniqueLanguageCodes.add(language.bcpCode);
    }

    final List<Locale> allLocales =
        uniqueLanguageCodes.map((code) => Locale(code)).toList();

    supportedLocales.clear();
    supportedLocales.addAll(allLocales);

    // Sort locales alphabetically by language name for better UX
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

      // Check if this is an ML Kit language (not natively supported)
      const nativelySupported = ['mg', 'en', 'fr'];
      final isMLKitLanguage = !nativelySupported.contains(locale.languageCode);

      // Show loading overlay for ML Kit languages
      if (isMLKitLanguage && Get.context != null) {
        Get.dialog(
          WillPopScope(
            onWillPop: () async => false, // Prevent dismissing
            child: Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Preparing translation...',
                          style: Get.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This may take a moment for first-time use',
                          style: Get.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          barrierDismissible: false,
        );
      }

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

      // For ML Kit languages, wait a bit for pre-translation to complete
      if (isMLKitLanguage) {
        await Future.delayed(const Duration(milliseconds: 1500));
        // Close the loading dialog
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
      }

      debugPrint('Language successfully changed to: ${locale.languageCode}');
    } catch (e) {
      debugPrint('Error changing language: $e');
      // Close loading dialog if there was an error
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
    }
  }

  String getLanguageName(Locale locale) {
    // Complete mapping for all ML Kit supported languages
    switch (locale.languageCode) {
      case 'mg':
        return 'Malagasy';
      case 'af':
        return 'Afrikaans';
      case 'ar':
        return 'العربية';
      case 'be':
        return 'Беларуская';
      case 'bg':
        return 'Български';
      case 'bn':
        return 'বাংলা';
      case 'ca':
        return 'Català';
      case 'cs':
        return 'Čeština';
      case 'cy':
        return 'Cymraeg';
      case 'da':
        return 'Dansk';
      case 'de':
        return 'Deutsch';
      case 'el':
        return 'Ελληνικά';
      case 'en':
        return 'English';
      case 'eo':
        return 'Esperanto';
      case 'es':
        return 'Español';
      case 'et':
        return 'Eesti';
      case 'fa':
        return 'فارسی';
      case 'fi':
        return 'Suomi';
      case 'fr':
        return 'Français';
      case 'ga':
        return 'Gaeilge';
      case 'gl':
        return 'Galego';
      case 'gu':
        return 'ગુજરાતી';
      case 'he':
        return 'עברית';
      case 'hi':
        return 'हिन्दी';
      case 'hr':
        return 'Hrvatski';
      case 'ht':
        return 'Kreyòl Ayisyen';
      case 'hu':
        return 'Magyar';
      case 'id':
        return 'Bahasa Indonesia';
      case 'is':
        return 'Íslenska';
      case 'it':
        return 'Italiano';
      case 'ja':
        return '日本語';
      case 'ka':
        return 'ქართული';
      case 'kn':
        return 'ಕನ್ನಡ';
      case 'ko':
        return '한국어';
      case 'lt':
        return 'Lietuvių';
      case 'lv':
        return 'Latviešu';
      case 'mk':
        return 'Македонски';
      case 'mr':
        return 'मराठी';
      case 'ms':
        return 'Bahasa Melayu';
      case 'mt':
        return 'Malti';
      case 'nl':
        return 'Nederlands';
      case 'no':
        return 'Norsk';
      case 'pl':
        return 'Polski';
      case 'pt':
        return 'Português';
      case 'ro':
        return 'Română';
      case 'ru':
        return 'Русский';
      case 'sk':
        return 'Slovenčina';
      case 'sl':
        return 'Slovenščina';
      case 'sq':
        return 'Shqip';
      case 'sv':
        return 'Svenska';
      case 'sw':
        return 'Kiswahili';
      case 'ta':
        return 'தமிழ்';
      case 'te':
        return 'తెలుగు';
      case 'th':
        return 'ไทย';
      case 'tl':
        return 'Tagalog';
      case 'tr':
        return 'Türkçe';
      case 'uk':
        return 'Українська';
      case 'ur':
        return 'اردو';
      case 'vi':
        return 'Tiếng Việt';
      case 'zh':
        return '中文';
      default:
        // Fallback to uppercase code if not found
        return locale.languageCode.toUpperCase();
    }
  }

  String getLanguageFlag(Locale locale) {
    switch (locale.languageCode) {
      case 'mg':
        return '🇲🇬';
      case 'af':
        return '🇿🇦';
      case 'ar':
        return '🇸🇦';
      case 'be':
        return '🇧🇾';
      case 'bg':
        return '🇧🇬';
      case 'bn':
        return '🇧🇩';
      case 'ca':
        return '🇪🇸';
      case 'cs':
        return '🇨🇿';
      case 'cy':
        return '🏴󠁧󠁢󠁷󠁬󠁳󠁿';
      case 'da':
        return '🇩🇰';
      case 'de':
        return '🇩🇪';
      case 'el':
        return '🇬🇷';
      case 'en':
        return '🇬🇧';
      case 'eo':
        return '🌐';
      case 'es':
        return '🇪🇸';
      case 'et':
        return '🇪🇪';
      case 'fa':
        return '🇮🇷';
      case 'fi':
        return '🇫🇮';
      case 'fr':
        return '🇫🇷';
      case 'ga':
        return '🇮🇪';
      case 'gl':
        return '🇪🇸';
      case 'gu':
        return '🇮🇳';
      case 'he':
        return '🇮🇱';
      case 'hi':
        return '🇮🇳';
      case 'hr':
        return '🇭🇷';
      case 'ht':
        return '🇭🇹';
      case 'hu':
        return '🇭🇺';
      case 'id':
        return '🇮🇩';
      case 'is':
        return '🇮🇸';
      case 'it':
        return '🇮🇹';
      case 'ja':
        return '🇯🇵';
      case 'ka':
        return '🇬🇪';
      case 'kn':
        return '🇮🇳';
      case 'ko':
        return '🇰🇷';
      case 'lt':
        return '🇱🇹';
      case 'lv':
        return '🇱🇻';
      case 'mk':
        return '🇲🇰';
      case 'mr':
        return '🇮🇳';
      case 'ms':
        return '🇲🇾';
      case 'mt':
        return '🇲🇹';
      case 'nl':
        return '🇳🇱';
      case 'no':
        return '🇳🇴';
      case 'pl':
        return '🇵🇱';
      case 'pt':
        return '🇵🇹';
      case 'ro':
        return '🇷🇴';
      case 'ru':
        return '🇷🇺';
      case 'sk':
        return '🇸🇰';
      case 'sl':
        return '🇸🇮';
      case 'sq':
        return '🇦🇱';
      case 'sv':
        return '🇸🇪';
      case 'sw':
        return '🇰🇪';
      case 'ta':
        return '🇱🇰';
      case 'te':
        return '🇮🇳';
      case 'th':
        return '🇹🇭';
      case 'tl':
        return '🇵🇭';
      case 'tr':
        return '🇹🇷';
      case 'uk':
        return '🇺🇦';
      case 'ur':
        return '🇵🇰';
      case 'vi':
        return '🇻🇳';
      case 'zh':
        return '🇨🇳';
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
