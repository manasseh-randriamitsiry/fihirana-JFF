import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

class FontController extends GetxController {
  final RxString currentFont = 'Lato'.obs;

  final Map<String, String> fontMap = {
    // Sans-Serif Fonts (Clean & Modern) - Best for UI
    'Lato': 'Lato',
    'Poppins': 'Poppins',
    'Roboto': 'Roboto',
    'Open Sans': 'OpenSans',
    'Montserrat': 'Montserrat',
    'Raleway': 'Raleway',
    'Nunito': 'Nunito',
    'Quicksand': 'Quicksand',
    'Ubuntu': 'Ubuntu',
    'Mulish': 'Mulish',
    'Inter': 'Inter',
    'Work Sans': 'WorkSans',
    'Manrope': 'Manrope',
    'DM Sans': 'DMSans',
    'Rubik': 'Rubik',
    'Karla': 'Karla',
    'Outfit': 'Outfit',
    'Plus Jakarta Sans': 'PlusJakartaSans',
    'Lexend': 'Lexend',
    'Archivo': 'Archivo',

    // Serif Fonts (Traditional & Elegant) - Best for Reading
    'Merriweather': 'Merriweather',
    'Playfair Display': 'PlayfairDisplay',
    'Lora': 'Lora',
    'Crimson Text': 'CrimsonText',
    'EB Garamond': 'EBGaramond',
    'Libre Baskerville': 'LibreBaskerville',
    'Cormorant': 'Cormorant',
    'Spectral': 'Spectral',
    'Bitter': 'Bitter',
    'Cardo': 'Cardo',

    // Rounded Fonts (Friendly & Soft)
    'Comfortaa': 'Comfortaa',
    'Varela Round': 'VarelaRound',
    'Fredoka': 'Fredoka',
    'Baloo 2': 'Baloo2',

    // Condensed Fonts (Space-Efficient)
    'Roboto Condensed': 'RobotoCondensed',
    'Oswald': 'Oswald',
    'Fjalla One': 'FjallaOne',

    // Display Fonts (Decorative & Stylish)
    'Dancing Script': 'DancingScript',
    'Pacifico': 'Pacifico',
    'Satisfy': 'Satisfy',
    'Great Vibes': 'GreatVibes',
    'Lobster': 'Lobster',
    'Righteous': 'Righteous',

    // Handwriting Fonts (Personal Touch)
    'Caveat': 'Caveat',
    'Kalam': 'Kalam',
    'Patrick Hand': 'PatrickHand',

    // Monospace (Code-like & Technical)
    'Roboto Mono': 'RobotoMono',
    'Source Code Pro': 'SourceCodePro',
    'JetBrains Mono': 'JetBrainsMono',
    'Fira Code': 'FiraCode',
  };

  List<String> get availableFonts => fontMap.keys.toList();

  TextStyle getFontStyle(String fontName, TextStyle? baseStyle) {
    baseStyle ??= const TextStyle();
    switch (fontName) {
      // Sans-Serif
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
      case 'Mulish':
        return GoogleFonts.mulish(textStyle: baseStyle);
      case 'Inter':
        return GoogleFonts.inter(textStyle: baseStyle);
      case 'Work Sans':
        return GoogleFonts.workSans(textStyle: baseStyle);
      case 'Manrope':
        return GoogleFonts.manrope(textStyle: baseStyle);
      case 'DM Sans':
        return GoogleFonts.dmSans(textStyle: baseStyle);
      case 'Rubik':
        return GoogleFonts.rubik(textStyle: baseStyle);
      case 'Karla':
        return GoogleFonts.karla(textStyle: baseStyle);
      case 'Outfit':
        return GoogleFonts.outfit(textStyle: baseStyle);
      case 'Plus Jakarta Sans':
        return GoogleFonts.plusJakartaSans(textStyle: baseStyle);
      case 'Lexend':
        return GoogleFonts.lexend(textStyle: baseStyle);
      case 'Archivo':
        return GoogleFonts.archivo(textStyle: baseStyle);

      // Serif
      case 'Merriweather':
        return GoogleFonts.merriweather(textStyle: baseStyle);
      case 'Playfair Display':
        return GoogleFonts.playfairDisplay(textStyle: baseStyle);
      case 'Lora':
        return GoogleFonts.lora(textStyle: baseStyle);
      case 'Crimson Text':
        return GoogleFonts.crimsonText(textStyle: baseStyle);
      case 'EB Garamond':
        return GoogleFonts.ebGaramond(textStyle: baseStyle);
      case 'Libre Baskerville':
        return GoogleFonts.libreBaskerville(textStyle: baseStyle);
      case 'Cormorant':
        return GoogleFonts.cormorant(textStyle: baseStyle);
      case 'Spectral':
        return GoogleFonts.spectral(textStyle: baseStyle);
      case 'Bitter':
        return GoogleFonts.bitter(textStyle: baseStyle);
      case 'Cardo':
        return GoogleFonts.cardo(textStyle: baseStyle);

      // Rounded
      case 'Comfortaa':
        return GoogleFonts.comfortaa(textStyle: baseStyle);
      case 'Varela Round':
        return GoogleFonts.varelaRound(textStyle: baseStyle);
      case 'Fredoka':
        return GoogleFonts.fredoka(textStyle: baseStyle);
      case 'Baloo 2':
        return GoogleFonts.baloo2(textStyle: baseStyle);

      // Condensed
      case 'Roboto Condensed':
        return GoogleFonts.robotoCondensed(textStyle: baseStyle);
      case 'Oswald':
        return GoogleFonts.oswald(textStyle: baseStyle);
      case 'Fjalla One':
        return GoogleFonts.fjallaOne(textStyle: baseStyle);

      // Display
      case 'Dancing Script':
        return GoogleFonts.dancingScript(textStyle: baseStyle);
      case 'Pacifico':
        return GoogleFonts.pacifico(textStyle: baseStyle);
      case 'Satisfy':
        return GoogleFonts.satisfy(textStyle: baseStyle);
      case 'Great Vibes':
        return GoogleFonts.greatVibes(textStyle: baseStyle);
      case 'Lobster':
        return GoogleFonts.lobster(textStyle: baseStyle);
      case 'Righteous':
        return GoogleFonts.righteous(textStyle: baseStyle);

      // Handwriting
      case 'Caveat':
        return GoogleFonts.caveat(textStyle: baseStyle);
      case 'Kalam':
        return GoogleFonts.kalam(textStyle: baseStyle);
      case 'Patrick Hand':
        return GoogleFonts.patrickHand(textStyle: baseStyle);

      // Monospace
      case 'Roboto Mono':
        return GoogleFonts.robotoMono(textStyle: baseStyle);
      case 'Source Code Pro':
        return GoogleFonts.sourceCodePro(textStyle: baseStyle);
      case 'JetBrains Mono':
        return GoogleFonts.jetBrainsMono(textStyle: baseStyle);
      case 'Fira Code':
        return GoogleFonts.firaCode(textStyle: baseStyle);

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
