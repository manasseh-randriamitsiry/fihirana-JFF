import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/app/theme/font_controller.dart';
import 'package:fihirana/core/design_system/app_typography.dart';

/// Resolves the font the user picked in Settings into the theme's body family.
///
/// The picked face runs the app; the display and figure families keep their own
/// roles, which a blanket `TextTheme.apply(fontFamily:)` would have erased.
class AppThemeManager {
  ColorController? _colorController;
  FontController? _fontController;

  ColorController get _getColorController =>
      _colorController ??= Get.find<ColorController>();

  FontController get _getFontController =>
      _fontController ??= Get.find<FontController>();

  String _bodyFamily(String fontName) {
    if (_getFontController.customFonts.contains(fontName)) return fontName;
    return _getFontController.fontMap[fontName] ??
        AppTypography.fallbackBodyFamily;
  }

  ThemeData getLightTheme(String fontName) =>
      _getColorController.getLightTheme(bodyFamily: _bodyFamily(fontName));

  ThemeData getDarkTheme(String fontName) =>
      _getColorController.getDarkTheme(bodyFamily: _bodyFamily(fontName));
}
