import 'package:flutter/material.dart';
import 'package:fihirana/l10n/app_localizations.dart';

extension BuildContextLocalization on BuildContext {
  /// Get localized text using AppLocalizations
  /// This replaces the ML Kit translation functionality
  String translate(String Function(AppLocalizations) getter) {
    final localizations = AppLocalizations.of(this);
    if (localizations == null) {
      // Return the key name if localization is not available
      return 'Localization not available';
    }
    try {
      return getter(localizations);
    } catch (e) {
      // Return error message if the key is not found
      return 'Translation error: $e';
    }
  }
}