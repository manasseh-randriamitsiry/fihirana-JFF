import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/app/theme/font_controller.dart';

/// Manages application theming and theme generation
class AppThemeManager {
  ColorController? _colorController;
  FontController? _fontController;

  ColorController get _getColorController {
    _colorController ??= Get.find<ColorController>();
    return _colorController!;
  }

  FontController get _getFontController {
    _fontController ??= Get.find<FontController>();
    return _fontController!;
  }

  /// Get the appropriate theme with font applied
  ThemeData getThemeWithFont(ThemeData baseTheme, String fontName) {
    // Check if it's a custom font first
    String fontFamily;
    if (_getFontController.customFonts.contains(fontName)) {
      // For custom fonts, use the font name directly as the family name
      fontFamily = fontName;
    } else {
      // For predefined fonts, get from the map or default to 'Lato'
      fontFamily = _getFontController.fontMap[fontName] ?? 'Lato';
    }

    return baseTheme.copyWith(
      textTheme: baseTheme.textTheme.apply(fontFamily: fontFamily),
      primaryTextTheme:
          baseTheme.primaryTextTheme.apply(fontFamily: fontFamily),
    );
  }

  /// Get light theme
  ThemeData getLightTheme(String fontName) {
    return getThemeWithFont(_getColorController.getLightTheme(), fontName);
  }

  /// Get dark theme
  ThemeData getDarkTheme(String fontName) {
    return getThemeWithFont(_getColorController.getDarkTheme(), fontName);
  }
}