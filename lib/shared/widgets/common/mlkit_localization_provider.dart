import 'package:flutter/material.dart';
import 'package:fihirana/l10n/app_localizations.dart';

extension MLKitLocalization on BuildContext {
  /// Translate text using ML Kit (placeholder implementation)
  /// This method provides a fallback to regular localization
  Future<String> translateWithMLKit(String text, {String? targetLanguage}) async {
    try {
      AppLocalizations.of(this);
      
      // For now, just return the original text as placeholder
      // In a real implementation, you would integrate with ML Kit translation
      return text;
    } catch (e) {
      return text; // Return original text on error
    }
  }
  
  /// Get current locale for ML Kit
  Locale? getCurrentLocale() {
    AppLocalizations.of(this);
    
    // Try to get the locale from the context
    return Localizations.localeOf(this);
  }
  
  /// Check if ML Kit translation is available
  bool isMLKitTranslationAvailable() {
    // For now, return false as placeholder
    // In a real implementation, you would check if ML Kit is available
    return false;
  }
}