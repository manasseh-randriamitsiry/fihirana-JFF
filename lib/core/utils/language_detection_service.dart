import 'package:flutter/foundation.dart';

class LanguageDetectionService {
  // Constructor for controllers that expect new LanguageDetectionService()
  LanguageDetectionService();

  // Initialize language detection service
  Future<void> initialize() async {
    // Initialize language detection capabilities
    if (kDebugMode) {
      print('LanguageDetectionService initialized');
    }
  }

  // Detect language of given text
  Future<String> detectLanguage(String text) async {
    try {
      if (text.isEmpty) return 'en';

      // Simple heuristic-based language detection as placeholder
      // In a real implementation, you would use ML Kit or similar

      // Check for French characters/words
      if (RegExp(r'[àâäéèêëïîôöùûüÿç]').hasMatch(text) ||
          text.toLowerCase().contains(RegExp(
              r'\b(le|la|les|de|du|des|et|est|dans|pour|que|qui|ce|se|ne|me|te|lui|leur|y|en)\b'))) {
        return 'fr';
      }

      // Check for Malagasy characters/words
      if (text
          .toLowerCase()
          .contains(RegExp(r'\b(ny|ho|dia|amin|tsy|mitovy)\b'))) {
        return 'mg';
      }

      // Default to English
      return 'en';
    } catch (e) {
      if (kDebugMode) {
        print('Language detection error: $e');
      }
      return 'en';
    }
  }

  // Get source language (alias for detectLanguage)
  Future<String> getSourceLanguage(String text) async {
    return detectLanguage(text);
  }

  // Check if translation is needed
  Future<bool> needsTranslation(String text, String targetLanguage) async {
    final detectedLanguage = await detectLanguage(text);
    return detectedLanguage != targetLanguage;
  }

  // Get confidence score for language detection
  Future<double> getConfidence(String text, String detectedLanguage) async {
    try {
      // Simple confidence calculation based on text length and language indicators
      if (text.isEmpty) return 0.0;

      double confidence = 0.5; // Base confidence

      // Increase confidence based on text length
      if (text.length > 50) confidence += 0.2;
      if (text.length > 100) confidence += 0.1;

      // Increase confidence if we found strong language indicators
      switch (detectedLanguage) {
        case 'fr':
          if (RegExp(r'[àâäéèêëïîôöùûüÿç]').hasMatch(text)) confidence += 0.3;
          break;

        case 'mg':
          if (text.toLowerCase().contains('ny') ||
              text.toLowerCase().contains('ho')) {
            confidence += 0.3;
          }
          break;
        case 'en':
          if (RegExp(
                  r'\b(the|and|is|are|was|were|have|has|will|would|could|should)\b',
                  caseSensitive: false)
              .hasMatch(text)) {
            confidence += 0.3;
          }
          break;
      }

      return confidence.clamp(0.0, 1.0);
    } catch (e) {
      if (kDebugMode) {
        print('Confidence calculation error: $e');
      }
      return 0.5;
    }
  }

  // Get multiple language predictions with confidence scores
  Future<Map<String, double>> getLanguagePredictions(String text) async {
    try {
      final detectedLanguage = await detectLanguage(text);
      final confidence = await getConfidence(text, detectedLanguage);

      return {
        detectedLanguage: confidence,
        // Add other languages with lower confidence
        'en': detectedLanguage == 'en' ? confidence : 0.1,
        'fr': detectedLanguage == 'fr' ? confidence : 0.1,

        'mg': detectedLanguage == 'mg' ? confidence : 0.1,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Language predictions error: $e');
      }
      return {'en': 0.5};
    }
  }

  // Get supported languages
  Map<String, String> get supportedLanguages => {
        'en': 'English',
        'fr': 'Français',
        'mg': 'Malagasy',
      };

  // Get language name from code
  String getLanguageName(String code) {
    return supportedLanguages[code] ?? code;
  }

  // Check if language is supported
  bool isLanguageSupported(String language) {
    return supportedLanguages.containsKey(language);
  }

  // Dispose service
  void dispose() {
    // Placeholder for cleanup
    if (kDebugMode) {
      print('LanguageDetectionService disposed');
    }
  }
}
