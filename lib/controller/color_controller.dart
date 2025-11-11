import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ColorController extends GetxController {
  static ColorController get to => Get.find();

  final Rx<Color> primaryColor = Color(0xFF9C27B0).obs; // Colors.purple
  final Rx<Color> accentColor = Color(0xFFFF5722).obs; // Colors.deepOrange
  final Rx<Color> textColor = Color(0xFF000000).obs; // Colors.black
  final Rx<Color> backgroundColor = Color(0xFFFFFFFF).obs; // Colors.white
  final Rx<Color> drawerColor = Color(0xFF9C27B0).obs; // Colors.purple
  final Rx<Color> iconColor = Color(0xFF000000).obs; // Colors.black

  final RxInt currentSchemeIndex = 0.obs;

  final List<Map<String, dynamic>> colorSchemes = [
    {
      'name': 'Default',
      'primary': Color(0xFF2196F3), // Colors.blue
      'accent': Color(0xFF40C4FF), // Colors.blueAccent
      'text': Color(0xDD000000), // Colors.black87
      'background': Color(0xFFFFFFFF), // Colors.white
      'drawer': Color(0xFF6A1B9A), // Colors.purple.shade900
      'icon': Color(0xFFFF5722), // Colors.deepOrange
    },
    {
      'name': 'Ocean Blue',
      'primary': Color(0xFF2196F3), // Colors.blue
      'accent': Color(0xFFFFD600), // Colors.amber
      'text': Color(0xDD000000), // Colors.black87
      'background': Color(0xFFFFFFFF), // Colors.white
      'drawer': Color(0xFF0D47A1), // Colors.blue.shade900
      'icon': Color(0xFFFFD600), // Colors.amber
    },
    {
      'name': 'Forest Green',
      'primary': Color(0xFF009688), // Colors.teal
      'accent': Color(0xFFE91E63), // Colors.pink
      'text': Color(0xFF000000), // Colors.black
      'background': Color(0xFFFFFFFF), // Colors.white
      'drawer': Color(0xFF004D40), // Colors.teal.shade900
      'icon': Color(0xFFE91E63), // Colors.pink
    },
    {
      'name': 'Royal Purple',
      'primary': Color(0xFF3F51B5), // Colors.indigo
      'accent': Color(0xFFFF9800), // Colors.orange
      'text': Color(0xDD000000), // Colors.black87
      'background': Color(0xFFFFFFFF), // Colors.white
      'drawer': Color(0xFF1A237E), // Colors.indigo.shade900
      'icon': Color(0xFFFF9800), // Colors.orange
    },
  ];

  MaterialColor getMaterialColor(Color color) {
    final int red = color.red;
    final int green = color.green;
    final int blue = color.blue;
    final int alpha = color.alpha;

    final Map<int, Color> shades = {
      50: Color.fromARGB(alpha, red, green, blue).withOpacity(0.1),
      100: Color.fromARGB(alpha, red, green, blue).withOpacity(0.2),
      200: Color.fromARGB(alpha, red, green, blue).withOpacity(0.3),
      300: Color.fromARGB(alpha, red, green, blue).withOpacity(0.4),
      400: Color.fromARGB(alpha, red, green, blue).withOpacity(0.5),
      500: Color.fromARGB(alpha, red, green, blue).withOpacity(0.6),
      600: Color.fromARGB(alpha, red, green, blue).withOpacity(0.7),
      700: Color.fromARGB(alpha, red, green, blue).withOpacity(0.8),
      800: Color.fromARGB(alpha, red, green, blue).withOpacity(0.9),
      900: Color.fromARGB(alpha, red, green, blue).withOpacity(1.0),
    };

    return MaterialColor(color.value, shades);
  }

  @override
  void onInit() {
    super.onInit();
    loadColors();
  }

  Future<void> loadColors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      print('=== LOADING COLORS FROM SHARED PREFERENCES ===');
      
      currentSchemeIndex.value = prefs.getInt('currentSchemeIndex') ?? 0;
      print('Current scheme index: ${currentSchemeIndex.value}');
      
      // Print all raw values from SharedPreferences
      final primaryColorValue = prefs.getInt('primaryColor');
      final accentColorValue = prefs.getInt('accentColor');
      final textColorValue = prefs.getInt('textColor');
      final backgroundColorValue = prefs.getInt('backgroundColor');
      final drawerColorValue = prefs.getInt('drawerColor');
      final iconColorValue = prefs.getInt('iconColor');
      
      print('Raw values from SharedPreferences:');
      print('  primaryColor: $primaryColorValue');
      print('  accentColor: $accentColorValue');
      print('  textColor: $textColorValue');
      print('  backgroundColor: $backgroundColorValue');
      print('  drawerColor: $drawerColorValue');
      print('  iconColor: $iconColorValue');
      
      // Load colors with defaults if null
      primaryColor.value = Color(primaryColorValue ?? 0xFF2196F3); // Colors.blue
      accentColor.value = Color(accentColorValue ?? 0xFFFF5722); // Colors.deepOrange
      textColor.value = Color(textColorValue ?? 0xFF000000); // Colors.black
      backgroundColor.value = Color(backgroundColorValue ?? 0xFFFFFFFF); // Colors.white
      drawerColor.value = Color(drawerColorValue ?? 0xFF9C27B0); // Colors.purple
      iconColor.value = Color(iconColorValue ?? 0xFF000000); // Colors.black
      
      print('Loaded colors after assignment:');
      print('  primaryColor: ${primaryColor.value}');
      print('  accentColor: ${accentColor.value}');
      print('  textColor: ${textColor.value}');
      print('  backgroundColor: ${backgroundColor.value}');
      print('  drawerColor: ${drawerColor.value}');
      print('  iconColor: ${iconColor.value}');
      print('=== END LOADING COLORS ===');

      // Apply system UI overlay style after loading colors
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: _isDark(backgroundColor.value)
              ? Brightness.light
              : Brightness.dark,
          systemNavigationBarColor: backgroundColor.value,
          systemNavigationBarIconBrightness: _isDark(backgroundColor.value)
              ? Brightness.light
              : Brightness.dark,
        ),
      );

      update();
    } catch (e) {
      print('Error loading colors: $e');
    }
  }

  Future<void> setColorScheme(int index) async {
    try {
      if (index >= 0 && index < colorSchemes.length) {
        final scheme = colorSchemes[index];
        currentSchemeIndex.value = index;

        final primary = scheme['primary'] as Color;
        primaryColor.value = primary;

        accentColor.value = scheme['accent'] as Color;
        textColor.value = scheme['text'] as Color;
        backgroundColor.value = scheme['background'] as Color;
        drawerColor.value = scheme['drawer'] as Color;
        iconColor.value = scheme['icon'] as Color;

        final prefs = await SharedPreferences.getInstance();
        print('=== SAVING COLOR SCHEME $index ===');
        print('Primary: ${primaryColor.value} -> ${primaryColor.value.value}');
        print('Accent: ${accentColor.value} -> ${accentColor.value.value}');
        print('Text: ${textColor.value} -> ${textColor.value.value}');
        print('Background: ${backgroundColor.value} -> ${backgroundColor.value.value}');
        print('Drawer: ${drawerColor.value} -> ${drawerColor.value.value}');
        print('Icon: ${iconColor.value} -> ${iconColor.value.value}');
        
        await prefs.setInt('primaryColor', primaryColor.value.value);
        await prefs.setInt('accentColor', accentColor.value.value);
        await prefs.setInt('textColor', textColor.value.value);
        await prefs.setInt('backgroundColor', backgroundColor.value.value);
        await prefs.setInt('drawerColor', drawerColor.value.value);
        await prefs.setInt('iconColor', iconColor.value.value);
        await prefs.setInt('currentSchemeIndex', currentSchemeIndex.value);
        
        print('=== VERIFYING SCHEME SAVE ===');
        print('Verified primaryColor: ${prefs.getInt('primaryColor')}');
        print('Verified accentColor: ${prefs.getInt('accentColor')}');
        print('Verified textColor: ${prefs.getInt('textColor')}');
        print('Verified backgroundColor: ${prefs.getInt('backgroundColor')}');
        print('Verified drawerColor: ${prefs.getInt('drawerColor')}');
        print('Verified iconColor: ${prefs.getInt('iconColor')}');
        print('=== END SAVING COLOR SCHEME ===');

        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: _isDark(backgroundColor.value)
                ? Brightness.light
                : Brightness.dark,
            systemNavigationBarColor: backgroundColor.value,
            systemNavigationBarIconBrightness: _isDark(backgroundColor.value)
                ? Brightness.light
                : Brightness.dark,
          ),
        );

        update();
        Get.forceAppUpdate();
      }
    } catch (e) {}
  }

  bool _isDark(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark;
  }

  String get currentSchemeName =>
      colorSchemes[currentSchemeIndex.value]['name'] as String;

  ThemeMode get themeMode =>
      _isDark(backgroundColor.value) ? ThemeMode.dark : ThemeMode.light;

  Future<void> nextColorScheme() async {
    int nextIndex = (currentSchemeIndex.value + 1) % colorSchemes.length;
    await setColorScheme(nextIndex);
  }

  Future<void> previousColorScheme() async {
    int prevIndex = currentSchemeIndex.value - 1;
    if (prevIndex < 0) prevIndex = colorSchemes.length - 1;
    await setColorScheme(prevIndex);
  }

  Future<void> updateIconColor(Color newColor) async {
    try {
      print('=== UPDATING ICON COLOR ===');
      iconColor.value = newColor;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('iconColor', newColor.value);
      print('Saved iconColor: $newColor -> ${newColor.value}');
      print('Verified saved iconColor: ${prefs.getInt('iconColor')}');
      update(['iconColor']);
      print('=== END UPDATING ICON COLOR ===');
    } catch (e) {
      print('Error saving iconColor: $e');
    }
  }

  Future<void> updateDrawerColor(Color newColor) async {
    try {
      print('=== UPDATING DRAWER COLOR ===');
      drawerColor.value = newColor;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('drawerColor', newColor.value);
      print('Saved drawerColor: $newColor -> ${newColor.value}');
      print('Verified saved drawerColor: ${prefs.getInt('drawerColor')}');
      update();
      print('=== END UPDATING DRAWER COLOR ===');
    } catch (e) {
      print('Error saving drawerColor: $e');
    }
  }

  Future<void> updateColors({
    Color? primary,
    Color? accent,
    Color? text,
    Color? background,
    Color? drawer,
    Color? icon,
  }) async {
    print('=== SAVING COLORS ===');
    final prefs = await SharedPreferences.getInstance();
    
    if (primary != null) {
      primaryColor.value = primary;
      print('Primary color being saved: ${primaryColor.value} -> ${primaryColor.value.value}');
      await prefs.setInt('primaryColor', primaryColor.value.value);
    }
    if (accent != null) {
      accentColor.value = accent;
      print('Accent color being saved: ${accentColor.value} -> ${accentColor.value.value}');
      await prefs.setInt('accentColor', accentColor.value.value);
    }
    if (text != null) {
      textColor.value = text;
      print('Text color being saved: ${textColor.value} -> ${textColor.value.value}');
      await prefs.setInt('textColor', textColor.value.value);
    }
    if (background != null) {
      backgroundColor.value = background;
      print('Background color being saved: ${backgroundColor.value} -> ${backgroundColor.value.value}');
      await prefs.setInt('backgroundColor', backgroundColor.value.value);
    }
    if (drawer != null) {
      drawerColor.value = drawer;
      print('Drawer color being saved: ${drawerColor.value} -> ${drawerColor.value.value}');
      await prefs.setInt('drawerColor', drawerColor.value.value);
    }
    if (icon != null) {
      iconColor.value = icon;
      print('Icon color being saved: ${iconColor.value} -> ${iconColor.value.value}');
      await prefs.setInt('iconColor', iconColor.value.value);
    }
    
    print('=== VERIFYING SAVED VALUES ===');
    print('Saved primaryColor: ${prefs.getInt('primaryColor')}');
    print('Saved accentColor: ${prefs.getInt('accentColor')}');
    print('Saved textColor: ${prefs.getInt('textColor')}');
    print('Saved backgroundColor: ${prefs.getInt('backgroundColor')}');
    print('Saved drawerColor: ${prefs.getInt('drawerColor')}');
    print('Saved iconColor: ${prefs.getInt('iconColor')}');
    print('=== END SAVING COLORS ===');

    // Apply system UI overlay style after color changes
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _isDark(backgroundColor.value)
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarColor: backgroundColor.value,
        systemNavigationBarIconBrightness: _isDark(backgroundColor.value)
            ? Brightness.light
            : Brightness.dark,
      ),
    );

    update();
    Get.forceAppUpdate();

    if (accent != null) {
      accentColor.value = accent;
      print('Accent color being saved: ${accentColor.value}');
      await prefs.setInt('accentColor', accentColor.value.value);
    }
    if (text != null) {
      textColor.value = text;
      print('Text color being saved: ${textColor.value}');
      await prefs.setInt('textColor', textColor.value.value);
    }
    if (background != null) {
      backgroundColor.value = background;
      print('Background color being saved: ${backgroundColor.value}');
      await prefs.setInt('backgroundColor', backgroundColor.value.value);
    }
    if (drawer != null) {
      drawerColor.value = drawer;
      print('Drawer color being saved: ${drawerColor.value}');
      await prefs.setInt('drawerColor', drawerColor.value.value);
    }
    if (icon != null) {
      iconColor.value = icon;
      print('Icon color being saved: ${iconColor.value}');
      await prefs.setInt('iconColor', iconColor.value.value);
    }

    // Apply system UI overlay style after color changes
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _isDark(backgroundColor.value)
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarColor: backgroundColor.value,
        systemNavigationBarIconBrightness: _isDark(backgroundColor.value)
            ? Brightness.light
            : Brightness.dark,
      ),
    );

    update();
    Get.forceAppUpdate();
  }

  Future<void> saveAllColors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('primaryColor', primaryColor.value.value);
      await prefs.setInt('accentColor', accentColor.value.value);
      await prefs.setInt('textColor', textColor.value.value);
      await prefs.setInt('backgroundColor', backgroundColor.value.value);
      await prefs.setInt('drawerColor', drawerColor.value.value);
      await prefs.setInt('iconColor', iconColor.value.value);
      await prefs.setInt('currentSchemeIndex', currentSchemeIndex.value);
    } catch (e) {}
  }

  Future<void> saveColors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('iconColor', iconColor.value.value);
    } catch (e) {}
  }

  ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor.value,
      colorScheme: ColorScheme.light(
        primary: primaryColor.value,
        secondary: accentColor.value,
        surface: backgroundColor.value,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textColor.value,
      ),
      scaffoldBackgroundColor: backgroundColor.value,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor.value,
        foregroundColor: Colors.white,
      ),
      iconTheme: IconThemeData(
        color: iconColor.value,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: textColor.value),
        bodyMedium: TextStyle(color: textColor.value),
        titleLarge: TextStyle(color: textColor.value),
      ).apply(
        bodyColor: textColor.value,
        displayColor: textColor.value,
      ),
    );
  }

  ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor.value,
      colorScheme: ColorScheme.dark(
        primary: primaryColor.value,
        secondary: accentColor.value,
        surface: Colors.black,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor.value,
        foregroundColor: Colors.white,
      ),
      iconTheme: const IconThemeData(
        color: Colors.white,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        titleLarge: TextStyle(color: Colors.white),
      ).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
  }

  NeumorphicThemeData getNeumorphicLightTheme() {
    return NeumorphicThemeData(
      baseColor: backgroundColor.value,
      accentColor: accentColor.value,
      lightSource: LightSource.topLeft,
      depth: 8,
      intensity: 0.65,
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: textColor.value),
        bodyMedium: TextStyle(color: textColor.value),
        titleLarge: TextStyle(color: textColor.value),
      ),
    );
  }

  NeumorphicThemeData getNeumorphicDarkTheme() {
    return NeumorphicThemeData(
      baseColor: Colors.black,
      accentColor: accentColor.value,
      lightSource: LightSource.topLeft,
      depth: 8,
      intensity: 0.65,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        titleLarge: TextStyle(color: Colors.white),
      ),
    );
  }
}
