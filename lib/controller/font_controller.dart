import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

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

    // Edu Fonts (Handwriting / School)
    'Edu NSW ACT Foundation': 'EduNSWACTFoundation',
    'Edu QLD Beginner': 'EduQLDBeginner',
    'Edu SA Beginner': 'EduSABeginner',
    'Edu TAS Beginner': 'EduTASBeginner',
    'Edu VIC WANT Beginner': 'EduVICWANTBeginner',
  };

  final RxList<String> customFonts = <String>[].obs;

  List<String> get availableFonts => [...fontMap.keys, ...customFonts];

  TextStyle getFontStyle(String fontName, TextStyle? baseStyle) {
    baseStyle ??= const TextStyle();

    // Check if it's a custom font
    if (customFonts.contains(fontName)) {
      return baseStyle.copyWith(fontFamily: fontName);
    }

    // Get the font family name from the map, or default to Lato
    final fontFamily = fontMap[fontName] ?? 'Lato';

    return baseStyle.copyWith(fontFamily: fontFamily);
  }

  @override
  void onInit() {
    super.onInit();
    loadCustomFonts();
    loadFont();
  }

  Future<void> loadFont() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedFont = prefs.getString('selectedFont');
    if (savedFont != null &&
        (fontMap.containsKey(savedFont) || customFonts.contains(savedFont))) {
      currentFont.value = savedFont;
    }
  }

  Future<void> changeFont(String font) async {
    if (fontMap.containsKey(font) || customFonts.contains(font)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedFont', font);
      currentFont.value = font;
    }
  }

  Future<void> loadCustomFonts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCustomFonts = prefs.getStringList('customFonts') ?? [];

      for (final fontPath in savedCustomFonts) {
        final file = File(fontPath);
        if (await file.exists()) {
          final fontName =
              path.basenameWithoutExtension(fontPath).replaceAll('-', ' ');
          await _loadFontFromFile(fontName, file);
          customFonts.add(fontName);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading custom fonts: $e');
      }
    }
  }

  Future<void> importFont() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ttf', 'otf'],
      );

      if (result != null && result.files.single.path != null) {
        final sourceFile = File(result.files.single.path!);
        final appDir = await getApplicationDocumentsDirectory();
        final fontsDir = Directory('${appDir.path}/custom_fonts');

        if (!await fontsDir.exists()) {
          await fontsDir.create(recursive: true);
        }

        final fileName = path.basename(sourceFile.path);
        final targetPath = '${fontsDir.path}/$fileName';
        final targetFile = await sourceFile.copy(targetPath);

        final fontName =
            path.basenameWithoutExtension(fileName).replaceAll('-', ' ');

        await _loadFontFromFile(fontName, targetFile);

        customFonts.add(fontName);

        // Save to prefs
        final prefs = await SharedPreferences.getInstance();
        final savedCustomFonts = prefs.getStringList('customFonts') ?? [];
        if (!savedCustomFonts.contains(targetPath)) {
          savedCustomFonts.add(targetPath);
          await prefs.setStringList('customFonts', savedCustomFonts);
        }

        // Auto-select the new font
        await changeFont(fontName);

        Get.snackbar(
          'Success',
          'Font "$fontName" imported successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to import font: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      if (kDebugMode) {
        print('Error importing font: $e');
      }
    }
  }

  Future<void> _loadFontFromFile(String fontName, File file) async {
    final fontLoader = FontLoader(fontName);
    fontLoader.addFont(Future.value(
        ByteData.view(await file.readAsBytes().then((bytes) => bytes.buffer))));
    await fontLoader.load();
  }
}
