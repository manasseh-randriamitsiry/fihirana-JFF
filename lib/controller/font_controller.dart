import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class FontController extends GetxController {
  final RxString currentFont = 'Lato'.obs;

  final Map<String, String> fontMap = {
    // Sans-Serif (Clean & Modern)
    'Lato': 'Lato',
    'Poppins': 'Poppins',
    'Open Sans': 'OpenSans',
    'Roboto': 'Roboto',
    'Montserrat': 'Montserrat',
    'Raleway': 'Raleway',
    'Titillium Web': 'TitilliumWeb',
    'Museo Sans Rounded': 'MuseoSansRounded',

    // Serif (Traditional & Elegant)
    'Source Serif Pro': 'SourceSerifPro',

    // Monospace (Code-like)
    'Hack': 'Hack',

    // Display / Decorative
    'GoBold': 'GoBold',
    'Soda Fountain': 'SodaFountain',

    // Handwriting
    'Breathing': 'Breathing',
  };

  List<String> get availableFonts => fontMap.keys.toList();

  TextStyle getFontStyle(String fontName, TextStyle? baseStyle) {
    baseStyle ??= const TextStyle();

    // Get the font family name from the map, or default to Lato
    final fontFamily = fontMap[fontName] ?? 'Lato';

    return baseStyle.copyWith(fontFamily: fontFamily);
  }

  @override
  void onInit() {
    super.onInit();
    loadFont();
  }

  Future<void> loadFont() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedFont = prefs.getString('selectedFont');
    if (savedFont != null && fontMap.containsKey(savedFont)) {
      currentFont.value = savedFont;
    }
  }

  Future<void> changeFont(String font) async {
    if (fontMap.containsKey(font)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedFont', font);
      currentFont.value = font;
    }
  }
}
