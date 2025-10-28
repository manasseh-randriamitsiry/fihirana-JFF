import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

class FontController extends GetxController {
  final RxString currentFont = 'Lato'.obs;

  final Map<String, String> fontMap = {
    'Lato': 'Lato',
    'Poppins': 'Poppins',
    'Roboto': 'Roboto',
    'Open Sans': 'OpenSans',
    'Montserrat': 'Montserrat',
    'Raleway': 'Raleway',
    'Nunito': 'Nunito',
    'Quicksand': 'Quicksand',
    'Ubuntu': 'Ubuntu',
    'Playfair Display': 'PlayfairDisplay',
    'Mulish': 'Mulish',
    'Merriweather': 'Merriweather',
    'Dancing Script': 'DancingScript',
    'Pacifico': 'Pacifico',
  };

  List<String> get availableFonts => fontMap.keys.toList();

  TextStyle getFontStyle(String fontName, TextStyle? baseStyle) {
    baseStyle ??= const TextStyle();
    switch (fontName) {
      case 'Lato':
        return GoogleFonts.lato(textStyle: baseStyle);
      case 'Poppins':
        return GoogleFonts.poppins(textStyle: baseStyle);
      case 'Roboto':
        return GoogleFonts.roboto(textStyle: baseStyle);
      case 'Open Sans':
        return GoogleFonts.openSans(textStyle: baseStyle);
      case 'Montserrat':
        return GoogleFonts.montserrat(textStyle: baseStyle);
      case 'Raleway':
        return GoogleFonts.raleway(textStyle: baseStyle);
      case 'Nunito':
        return GoogleFonts.nunito(textStyle: baseStyle);
      case 'Quicksand':
        return GoogleFonts.quicksand(textStyle: baseStyle);
      case 'Ubuntu':
        return GoogleFonts.ubuntu(textStyle: baseStyle);
      case 'Playfair Display':
        return GoogleFonts.playfairDisplay(textStyle: baseStyle);
      case 'Mulish':
        return GoogleFonts.mulish(textStyle: baseStyle);
      case 'Merriweather':
        return GoogleFonts.merriweather(textStyle: baseStyle);
      case 'Dancing Script':
        return GoogleFonts.dancingScript(textStyle: baseStyle);
      case 'Pacifico':
        return GoogleFonts.pacifico(textStyle: baseStyle);
      default:
        return GoogleFonts.lato(textStyle: baseStyle);
    }
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
