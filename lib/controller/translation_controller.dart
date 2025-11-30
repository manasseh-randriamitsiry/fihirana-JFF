import 'package:flutter/foundation.dart';
import '../services/translation_service.dart';
import '../services/language_detection_service.dart';

class TranslationController extends ChangeNotifier {
  final TranslationService _translationService = TranslationService();
  final LanguageDetectionService _languageDetectionService = LanguageDetectionService();
  
  bool _isTranslating = false;
  bool _isInitialized = false;
  String _currentLocale = 'en';
  bool _autoTranslate = true;
  
  // Translation cache for UI state
  final Map<String, String> _translatedTexts = {};
  final Map<String, bool> _translationStatus = {};

  // Getters
  bool get isTranslating => _isTranslating;
  bool get isInitialized => _isInitialized;
  String get currentLocale => _currentLocale;
  bool get autoTranslate => _autoTranslate;
  Map<String, String> get translatedTexts => Map.unmodifiable(_translatedTexts);

  /// Initialize the translation controller
  Future<void> initialize(String locale) async {
    if (_isInitialized) return;
    
    try {
      await _translationService.initialize();
      await _languageDetectionService.initialize();
      _currentLocale = locale;
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing translation controller: $e');
    }
  }

  /// Update current locale
  void updateLocale(String locale) {
    if (_currentLocale != locale) {
      _currentLocale = locale;
      // Clear translation cache when locale changes
      if (_autoTranslate) {
        _translatedTexts.clear();
        _translationStatus.clear();
      }
      notifyListeners();
    }
  }

  /// Toggle auto-translate feature
  void toggleAutoTranslate() {
    _autoTranslate = !_autoTranslate;
    if (!_autoTranslate) {
      _translatedTexts.clear();
      _translationStatus.clear();
    }
    notifyListeners();
  }

  /// Translate a single text
  Future<String> translateText(
    String text, {
    String? sourceLanguage,
    String? targetLanguage,
  }) async {
    if (text.trim().isEmpty) return text;

    final cacheKey = '${text.hashCode}_${targetLanguage ?? _currentLocale}';
    
    // Return cached translation if available
    if (_translatedTexts.containsKey(cacheKey)) {
      return _translatedTexts[cacheKey]!;
    }

    _isTranslating = true;
    _translationStatus[cacheKey] = true;
    notifyListeners();

    try {
      // Detect source language if not provided
      String fromLang = sourceLanguage ?? 'en';
      if (sourceLanguage == null) {
        fromLang = await _languageDetectionService.getSourceLanguage(text, _currentLocale);
      }

      final toLang = targetLanguage ?? _currentLocale;
      
      // Only translate if languages are different
      if (fromLang != toLang) {
        final translatedText = await _translationService.translateText(text, fromLang, toLang);
        _translatedTexts[cacheKey] = translatedText;
        return translatedText;
      } else {
        _translatedTexts[cacheKey] = text;
        return text;
      }
    } catch (e) {
      debugPrint('Translation error: $e');
      _translatedTexts[cacheKey] = text;
      return text;
    } finally {
      _isTranslating = false;
      _translationStatus[cacheKey] = false;
      notifyListeners();
    }
  }

  /// Auto-translate text if needed
  Future<String> autoTranslateIfNeeded(String text) async {
    if (!_autoTranslate || !_isInitialized || text.trim().isEmpty) {
      return text;
    }

    try {
      final needsTranslation = await _languageDetectionService.needsTranslation(text, _currentLocale);
      if (needsTranslation) {
        return await translateText(text);
      }
      return text;
    } catch (e) {
      debugPrint('Auto-translation error: $e');
      return text;
    }
  }

  /// Translate multiple texts in batch
  Future<Map<String, String>> translateBatch(
    Map<String, String> texts, {
    String? sourceLanguage,
    String? targetLanguage,
  }) async {
    if (texts.isEmpty) return {};

    _isTranslating = true;
    notifyListeners();

    try {
      final fromLang = sourceLanguage ?? 'en';
      final toLang = targetLanguage ?? _currentLocale;
      
      final results = await _translationService.translateBatch(texts, fromLang, toLang);
      
      // Update cache
      for (final entry in results.entries) {
        final cacheKey = '${entry.key.hashCode}_$toLang';
        _translatedTexts[cacheKey] = entry.value;
      }
      
      return results;
    } catch (e) {
      debugPrint('Batch translation error: $e');
      return texts; // Return original texts on error
    } finally {
      _isTranslating = false;
      notifyListeners();
    }
  }

  /// Check if text is currently being translated
  bool isTranslatingText(String text) {
    final cacheKey = '${text.hashCode}_${_currentLocale}';
    return _translationStatus[cacheKey] ?? false;
  }

  /// Get translated version of text if available
  String? getTranslatedText(String text) {
    final cacheKey = '${text.hashCode}_${_currentLocale}';
    return _translatedTexts[cacheKey];
  }

  /// Detect language of text
  Future<String?> detectLanguage(String text) async {
    return await _languageDetectionService.detectLanguage(text);
  }

  /// Get supported languages
  List<String> getSupportedLanguages() {
    return _translationService.supportedLanguages;
  }

  /// Check if language is supported
  bool isLanguageSupported(String languageCode) {
    return _translationService.isLanguageSupported(languageCode);
  }

  /// Get language name from code
  String getLanguageName(String languageCode) {
    return _translationService.getLanguageName(languageCode);
  }

  /// Clear translation cache
  void clearCache() {
    _translatedTexts.clear();
    _translationStatus.clear();
    _translationService.clearCache();
    notifyListeners();
  }

  /// Clear specific text from cache
  void clearTextFromCache(String text) {
    final keysToRemove = _translatedTexts.keys.where((key) => key.startsWith('${text.hashCode}_')).toList();
    for (final key in keysToRemove) {
      _translatedTexts.remove(key);
      _translationStatus.remove(key);
    }
    notifyListeners();
  }

  /// Get translation statistics
  Map<String, dynamic> getTranslationStats() {
    return {
      'cacheSize': _translatedTexts.length,
      'currentlyTranslating': _translationStatus.values.where((status) => status).length,
      'autoTranslateEnabled': _autoTranslate,
      'currentLocale': _currentLocale,
      'supportedLanguages': getSupportedLanguages(),
    };
  }

  @override
  void dispose() {
    _translationService.dispose();
    _languageDetectionService.dispose();
    _translatedTexts.clear();
    _translationStatus.clear();
    super.dispose();
  }
}