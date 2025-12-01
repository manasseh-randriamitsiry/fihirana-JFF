/// Abstract interface for Translation service operations
/// This allows for dependency injection and better testability
abstract class ITranslationService {
  /// Initialize the translation service
  Future<void> initialize();
  
  /// Translate text from source language to target language
  Future<String> translate({
    required String text,
    String sourceLanguage = 'auto',
    String targetLanguage = 'en',
  });
  
  /// Detect the language of the given text
  Future<String> detectLanguage(String text);
  
  /// Get supported languages for translation
  Future<List<String>> getSupportedLanguages();
  
  /// Check if a language is supported
  Future<bool> isLanguageSupported(String languageCode);
  
  /// Translate multiple texts at once
  Future<List<String>> translateMultiple({
    required List<String> texts,
    String sourceLanguage = 'auto',
    String targetLanguage = 'en',
  });
  
  /// Get available language pairs
  Future<Map<String, List<String>>> getLanguagePairs();
  
  /// Set translation API key (if needed)
  void setApiKey(String apiKey);
  
  /// Clear translation cache
  void clearCache();
  
  /// Get translation history
  List<TranslationEntry> getTranslationHistory();
  
  /// Save translation to history
  void saveToHistory(TranslationEntry entry);
  
  /// Clear translation history
  void clearHistory();
}

/// Model for translation history entries
class TranslationEntry {
  final String originalText;
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;
  final DateTime timestamp;
  
  TranslationEntry({
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'originalText': originalText,
      'translatedText': translatedText,
      'sourceLanguage': sourceLanguage,
      'targetLanguage': targetLanguage,
      'timestamp': timestamp.toIso8601String(),
    };
  }
  
  factory TranslationEntry.fromJson(Map<String, dynamic> json) {
    return TranslationEntry(
      originalText: json['originalText'],
      translatedText: json['translatedText'],
      sourceLanguage: json['sourceLanguage'],
      targetLanguage: json['targetLanguage'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}