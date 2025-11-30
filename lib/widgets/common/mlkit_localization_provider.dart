import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:fihirana/services/core/translation_service.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_en.dart';
import '../../controller/language_controller.dart';

class MLKitLocalizationProvider extends ChangeNotifier {
  final TranslationService _translationService = TranslationService();
  String _currentLanguage = 'en';
  bool _isMLKitEnabled = false;
  bool _isLoading = false;

  // Cache for translated strings: key = "sourceText_targetLang", value = translated text
  final Map<String, String> _translationCache = {};

  // Translation queue to prevent flooding
  final List<String> _translationQueue = [];
  bool _isProcessingQueue = false;
  static const int _maxConcurrentTranslations = 3;
  int _activeTranslations = 0;

  MLKitLocalizationProvider() {
    _initializeDefault();
  }

  // Getters
  String get currentLanguage => _currentLanguage;
  bool get isMLKitEnabled => _isMLKitEnabled;
  bool get isLoading => _isLoading;
  TranslationService get translationService => _translationService;

  // Initialize with default settings
  Future<void> _initializeDefault() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString('selected_language');
      if (savedLanguage != null) {
        await setLanguage(savedLanguage);
      } else {
        await setLanguage('en');
      }
    } catch (e) {
      await setLanguage('en');
    }
  }

  // Set language and initialize ML Kit if needed
  Future<void> setLanguage(String languageCode) async {
    if (_currentLanguage == languageCode && _isMLKitEnabled) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _currentLanguage = languageCode;

      // Check if this language has native AppLocalizations support
      const nativelySupported = ['mg', 'en', 'fr'];

      if (nativelySupported.contains(languageCode)) {
        // Use native translations, disable ML Kit
        _isMLKitEnabled = false;
        _translationCache.clear();
        _translationQueue.clear();
      } else {
        // Enable ML Kit for translation
        _isMLKitEnabled = true;
        _translationCache.clear(); // Clear cache when changing language
        _translationQueue.clear();

        // Test ML Kit availability by attempting a simple translation
        try {
          await _translationService.translate(
            text: 'test',
            sourceLanguage: 'en',
            targetLanguage: languageCode,
          );
        } catch (mlkitError) {
          if (kDebugMode) {
            print('ML Kit not available for $languageCode: $mlkitError');
          }
          // Fall back to disabled state if ML Kit fails
          _isMLKitEnabled = false;
        }
      }

      if (kDebugMode) {
        print(
            'MLKit language set to: $languageCode, enabled: $_isMLKitEnabled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting language: $e');
      }
      _isMLKitEnabled = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get translated string (synchronous, uses cache or returns English fallback)
  String getTranslatedString(
      BuildContext context, String Function(AppLocalizations) getter) {
    // Get AppLocalizations - might be null for unsupported locales
    AppLocalizations? appLocalizations = AppLocalizations.of(context);

    // For native languages (mg/en/fr), use AppLocalizations directly
    if (!_isMLKitEnabled && appLocalizations != null) {
      return getter(appLocalizations);
    }

    // For ML Kit languages or when appLocalizations is null, use English source
    final englishLocalizations = AppLocalizationsEn();
    final englishSourceText = getter(englishLocalizations);

    // If ML Kit is not enabled but appLocalizations was null, just return English
    if (!_isMLKitEnabled) {
      return englishSourceText;
    }

    // For ML Kit languages, translate from English to target
    // Check cache first
    final cacheKey = '${englishSourceText}_$_currentLanguage';
    if (_translationCache.containsKey(cacheKey)) {
      return _translationCache[cacheKey]!;
    }

    // If not in cache, add to queue for translation
    _queueTranslation(englishSourceText, _currentLanguage);

    // Return English text as fallback while translation is in progress
    return englishSourceText;
  }

  // Queue a translation request
  void _queueTranslation(String sourceText, String targetLanguage) {
    final cacheKey = '${sourceText}_$targetLanguage';

    // Don't queue if already cached, empty, or already queued
    if (_translationCache.containsKey(cacheKey) ||
        sourceText.isEmpty ||
        _translationQueue.contains(cacheKey)) {
      return;
    }

    _translationQueue.add(cacheKey);
    _processQueue();
  }

  // Process translation queue with concurrency limit
  Future<void> _processQueue() async {
    if (_isProcessingQueue || _translationQueue.isEmpty) {
      return;
    }

    _isProcessingQueue = true;

    while (_translationQueue.isNotEmpty &&
        _activeTranslations < _maxConcurrentTranslations) {
      final cacheKey = _translationQueue.removeAt(0);
      final parts = cacheKey.split('_');
      if (parts.length < 2) continue;

      final targetLang = parts.last;
      final sourceText = parts.sublist(0, parts.length - 1).join('_');

      _activeTranslations++;
      _translateSingle(sourceText, targetLang, cacheKey).then((_) {
        _activeTranslations--;
        if (_translationQueue.isNotEmpty) {
          _processQueue();
        }
      });
    }

    _isProcessingQueue = false;
  }

  // Translate a single string
  Future<void> _translateSingle(
      String sourceText, String targetLanguage, String cacheKey) async {
    try {
      final translated = await _translationService.translate(
        text: sourceText,
        sourceLanguage: 'en',
        targetLanguage: targetLanguage,
      );

      _translationCache[cacheKey] = translated;
      notifyListeners();

      if (kDebugMode) {
        print('Translated: "$sourceText" -> "$translated"');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Translation error for "$sourceText": $e');
      }
      // Cache the original text to prevent repeated translation attempts
      _translationCache[cacheKey] = sourceText;
    }
  }

  // Pre-translate common strings for better UX
  Future<void> preTranslateCommonStrings(BuildContext context) async {
    if (!_isMLKitEnabled) return;

    // Use English localizations as source
    final appLocalizations = AppLocalizationsEn();

    // List of commonly used strings to pre-translate (reduced to most critical ones)
    final commonStrings = [
      (l) => l.home,
      (l) => l.settings,
      (l) => l.favorites,
      (l) => l.search,
      (l) => l.cancel,
      (l) => l.ok,
      (l) => l.save,
      (l) => l.language,
    ];

    // Add to queue for translation
    for (final getter in commonStrings) {
      final sourceText = getter(appLocalizations);
      _queueTranslation(sourceText, _currentLanguage);
    }

    if (kDebugMode) {
      print('Queued ${commonStrings.length} common strings for translation');
    }
  }

  // Clear translation cache
  void clearCache() {
    _translationCache.clear();
    _translationQueue.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _translationService.dispose();
    super.dispose();
  }
}

// Widget to provide ML Kit localization
class MLKitLocalizationWrapper extends StatefulWidget {
  final Widget child;

  const MLKitLocalizationWrapper({super.key, required this.child});

  @override
  State<MLKitLocalizationWrapper> createState() =>
      _MLKitLocalizationWrapperState();
}

class _MLKitLocalizationWrapperState extends State<MLKitLocalizationWrapper> {
  late MLKitLocalizationProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = MLKitLocalizationProvider();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sync with LanguageController whenever dependencies change
    _syncWithLanguageController();
  }

  void _syncWithLanguageController() {
    try {
      // Use Get.find with a try-catch to safely get the controller
      final languageController = Get.find<LanguageController>();
      final targetLanguage =
          languageController.currentLocale.value.languageCode;

      if (_provider.currentLanguage != targetLanguage) {
        _provider.setLanguage(targetLanguage);

        // Pre-translate common strings after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _provider.preTranslateCommonStrings(context);
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing with LanguageController: $e');
      }
    }
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MLKitLocalizationProvider>.value(
      value: _provider,
      child: widget.child,
    );
  }
}

// Extension for easy access to ML Kit translations
extension BuildContextMLKit on BuildContext {
  MLKitLocalizationProvider get mlKitProvider =>
      Provider.of<MLKitLocalizationProvider>(this, listen: false);

  String translateWithMLKit(String Function(AppLocalizations) getter) {
    return Provider.of<MLKitLocalizationProvider>(this)
        .getTranslatedString(this, getter);
  }
}
