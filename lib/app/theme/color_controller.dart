import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class ColorController extends GetxController {
  static ColorController get to => Get.find();

  final Rx<Color> primaryColor = const Color(0xFF9C27B0).obs; // Colors.purple
  final Rx<Color> accentColor =
      const Color(0xFFFF5722).obs; // Colors.deepOrange
  final Rx<Color> textColor = const Color(0xFF000000).obs; // Colors.black
  final Rx<Color> backgroundColor = const Color(0xFFFFFFFF).obs; // Colors.white
  final Rx<Color> drawerColor = const Color(0xFF9C27B0).obs; // Colors.purple
  final Rx<Color> iconColor = const Color(0xFF000000).obs; // Colors.black

  final RxInt currentSchemeIndex = 0.obs;

  final List<Map<String, dynamic>> colorSchemes = [
    {
      'name': 'Default',
      'primary': const Color(0xFF2196F3), // Colors.blue
      'accent': const Color(0xFF40C4FF), // Colors.blueAccent
      'text': const Color(0xDD000000), // Colors.black87
      'background': const Color(0xFFFFFFFF), // Colors.white
      'drawer': const Color(0xFF6A1B9A), // Colors.purple.shade900
      'icon': const Color(0xFFFF5722), // Colors.deepOrange
    },
    {
      'name': 'Ocean Blue',
      'primary': const Color(0xFF2196F3), // Colors.blue
      'accent': const Color(0xFFFFD600), // Colors.amber
      'text': const Color(0xDD000000), // Colors.black87
      'background': const Color(0xFFFFFFFF), // Colors.white
      'drawer': const Color(0xFF0D47A1), // Colors.blue.shade900
      'icon': const Color(0xFFFFD600), // Colors.amber
    },
    {
      'name': 'Forest Green',
      'primary': const Color(0xFF009688), // Colors.teal
      'accent': const Color(0xFFE91E63), // Colors.pink
      'text': const Color(0xFF000000), // Colors.black
      'background': const Color(0xFFFFFFFF), // Colors.white
      'drawer': const Color(0xFF004D40), // Colors.teal.shade900
      'icon': const Color(0xFFE91E63), // Colors.pink
    },
    {
      'name': 'Royal Purple',
      'primary': const Color(0xFF3F51B5), // Colors.indigo
      'accent': const Color(0xFFFF9800), // Colors.orange
      'text': const Color(0xDD000000), // Colors.black87
      'background': const Color(0xFFFFFFFF), // Colors.white
      'drawer': const Color(0xFF1A237E), // Colors.indigo.shade900
      'icon': const Color(0xFFFF9800), // Colors.orange
    },
    {
      'name': 'AMOLED Black',
      'primary': const Color(0xFF00E676), // Bright green
      'accent': const Color(0xFF00BCD4), // Cyan
      'text': const Color(0xFFFFFFFF), // White text
      'background': const Color(0xFF000000), // Pure black for OLED
      'drawer': const Color(0xFF000000), // Pure black
      'icon': const Color(0xFF00E676), // Bright green
    },
    {
      'name': 'Dark Mode',
      'primary': const Color(0xFFBB86FC), // Light purple
      'accent': const Color(0xFF03DAC6), // Teal
      'text': const Color(0xFFE1E1E1), // Light gray text
      'background': const Color(0xFF121212), // Dark gray (Material Design dark)
      'drawer': const Color(0xFF1E1E1E), // Slightly lighter dark
      'icon': const Color(0xFF03DAC6), // Teal
    },
    {
      'name': 'Midnight Blue',
      'primary': const Color(0xFF5E92F3), // Light blue
      'accent': const Color(0xFF64FFDA), // Aqua
      'text': const Color(0xFFE8EAF6), // Very light blue-gray
      'background': const Color(0xFF0A1929), // Deep navy blue
      'drawer': const Color(0xFF001E3C), // Darker navy
      'icon': const Color(0xFF64FFDA), // Aqua
    },
    {
      'name': 'Sunset Orange',
      'primary': const Color(0xFFFF6F00), // Deep orange
      'accent': const Color(0xFFFFD54F), // Amber
      'text': const Color(0xFF212121), // Dark gray
      'background': const Color(0xFFFFF3E0), // Light orange
      'drawer': const Color(0xFFE65100), // Darker orange
      'icon': const Color(0xFFFF6F00), // Deep orange
    },
    {
      'name': 'Lavender Dream',
      'primary': const Color(0xFF9575CD), // Medium purple
      'accent': const Color(0xFFE91E63), // Pink
      'text': const Color(0xFF4A148C), // Deep purple
      'background': const Color(0xFFF3E5F5), // Very light purple
      'drawer': const Color(0xFF7B1FA2), // Dark purple
      'icon': const Color(0xFFE91E63), // Pink
    },
    {
      'name': 'Emerald Green',
      'primary': const Color(0xFF00C853), // Bright green
      'accent': const Color(0xFFFFEB3B), // Yellow
      'text': const Color(0xFF1B5E20), // Dark green
      'background': const Color(0xFFE8F5E9), // Very light green
      'drawer': const Color(0xFF2E7D32), // Medium green
      'icon': const Color(0xFF00C853), // Bright green
    },
    {
      'name': 'Rose Gold',
      'primary': const Color(0xFFE91E63), // Pink
      'accent': const Color(0xFFFFB74D), // Light orange/gold
      'text': const Color(0xFF880E4F), // Deep pink
      'background': const Color(0xFFFCE4EC), // Very light pink
      'drawer': const Color(0xFFC2185B), // Dark pink
      'icon': const Color(0xFFFFB74D), // Light orange/gold
    },
    {
      'name': 'Crimson Red',
      'primary': const Color(0xFFD32F2F), // Red
      'accent': const Color(0xFFFF5252), // Light red
      'text': const Color(0xFF212121), // Dark gray
      'background': const Color(0xFFFFEBEE), // Very light red
      'drawer': const Color(0xFFB71C1C), // Dark red
      'icon': const Color(0xFFD32F2F), // Red
    },
  ];

  MaterialColor getMaterialColor(Color color) {
    final int red = (color.r * 255.0).round() & 0xff;
    final int green = (color.g * 255.0).round() & 0xff;
    final int blue = (color.b * 255.0).round() & 0xff;
    final int alpha = (color.a * 255.0).round() & 0xff;

    final Map<int, Color> shades = {
      50: Color.fromARGB(alpha, red, green, blue).withValues(alpha: 0.1),
      100: Color.fromARGB(alpha, red, green, blue).withValues(alpha: 0.2),
      200: Color.fromARGB(alpha, red, green, blue).withValues(alpha: 0.3),
      300: Color.fromARGB(alpha, red, green, blue).withValues(alpha: 0.4),
      400: Color.fromARGB(alpha, red, green, blue).withValues(alpha: 0.5),
      500: Color.fromARGB(alpha, red, green, blue).withValues(alpha: 0.6),
      600: Color.fromARGB(alpha, red, green, blue).withValues(alpha: 0.7),
      700: Color.fromARGB(alpha, red, green, blue).withValues(alpha: 0.8),
      800: Color.fromARGB(alpha, red, green, blue).withValues(alpha: 0.9),
      900: Color.fromARGB(alpha, red, green, blue).withValues(alpha: 1.0),
    };

    return MaterialColor(color.toARGB32(), shades);
  }

  @override
  void onInit() {
    super.onInit();
    loadColors();
  }

  Future<void> loadColors() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final hasSavedScheme = prefs.containsKey('currentSchemeIndex');
      
      // Auto-switch to AMOLED if fresh install and system is dark
      if (!hasSavedScheme) {
        final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
        if (brightness == Brightness.dark) {
           await setColorScheme(4); // AMOLED Black
           return;
        }
      }

      currentSchemeIndex.value = prefs.getInt('currentSchemeIndex') ?? 0;

      // Load colors with defaults if null
      primaryColor.value = Color(prefs.getInt('primaryColor') ?? 0xFF2196F3);
      accentColor.value = Color(prefs.getInt('accentColor') ?? 0xFFFF5722);
      textColor.value = Color(prefs.getInt('textColor') ?? 0xFF000000);
      backgroundColor.value =
          Color(prefs.getInt('backgroundColor') ?? 0xFFFFFFFF);
      drawerColor.value = Color(prefs.getInt('drawerColor') ?? 0xFF9C27B0);
      iconColor.value = Color(prefs.getInt('iconColor') ?? 0xFF000000);

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
      // Silently handle errors
    }
  }

  Future<void> setColorScheme(int index) async {
    try {
      if (index >= 0 && index < colorSchemes.length) {
        final scheme = colorSchemes[index];
        currentSchemeIndex.value = index;

        primaryColor.value = scheme['primary'] as Color;
        accentColor.value = scheme['accent'] as Color;
        textColor.value = scheme['text'] as Color;
        backgroundColor.value = scheme['background'] as Color;
        drawerColor.value = scheme['drawer'] as Color;
        iconColor.value = scheme['icon'] as Color;

        final prefs = await SharedPreferences.getInstance();
        await Future.wait([
          prefs.setInt('primaryColor', primaryColor.value.toARGB32()),
          prefs.setInt('accentColor', accentColor.value.toARGB32()),
          prefs.setInt('textColor', textColor.value.toARGB32()),
          prefs.setInt('backgroundColor', backgroundColor.value.toARGB32()),
          prefs.setInt('drawerColor', drawerColor.value.toARGB32()),
          prefs.setInt('iconColor', iconColor.value.toARGB32()),
          prefs.setInt('currentSchemeIndex', currentSchemeIndex.value),
        ]);

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
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting color scheme: $e');
      }
    }
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
      iconColor.value = newColor;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('iconColor', newColor.toARGB32());
      update(['iconColor']);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating icon color: $e');
      }
    }
  }

  Future<void> updateDrawerColor(Color newColor) async {
    try {
      drawerColor.value = newColor;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('drawerColor', newColor.toARGB32());
      update();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating drawer color: $e');
      }
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
    final prefs = await SharedPreferences.getInstance();

    if (primary != null) {
      primaryColor.value = primary;
      await prefs.setInt('primaryColor', primaryColor.value.toARGB32());
    }
    if (accent != null) {
      accentColor.value = accent;
      await prefs.setInt('accentColor', accentColor.value.toARGB32());
    }
    if (text != null) {
      textColor.value = text;
      await prefs.setInt('textColor', textColor.value.toARGB32());
    }
    if (background != null) {
      backgroundColor.value = background;
      await prefs.setInt('backgroundColor', backgroundColor.value.toARGB32());
    }
    if (drawer != null) {
      drawerColor.value = drawer;
      await prefs.setInt('drawerColor', drawerColor.value.toARGB32());
    }
    if (icon != null) {
      iconColor.value = icon;
      await prefs.setInt('iconColor', iconColor.value.toARGB32());
    }

    // Apply system UI overlay style after color changes
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            _isDark(backgroundColor.value) ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: backgroundColor.value,
        systemNavigationBarIconBrightness:
            _isDark(backgroundColor.value) ? Brightness.light : Brightness.dark,
      ),
    );

    update();
    Get.forceAppUpdate();

    if (accent != null) {
      accentColor.value = accent;
      await prefs.setInt('accentColor', accentColor.value.toARGB32());
    }
    if (text != null) {
      textColor.value = text;
      await prefs.setInt('textColor', textColor.value.toARGB32());
    }
    if (background != null) {
      backgroundColor.value = background;
      await prefs.setInt('backgroundColor', backgroundColor.value.toARGB32());
    }
    if (drawer != null) {
      drawerColor.value = drawer;
      await prefs.setInt('drawerColor', drawerColor.value.toARGB32());
    }
    if (icon != null) {
      iconColor.value = icon;
      await prefs.setInt('iconColor', iconColor.value.toARGB32());
    }

    // Apply system UI overlay style after color changes
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            _isDark(backgroundColor.value) ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: backgroundColor.value,
        systemNavigationBarIconBrightness:
            _isDark(backgroundColor.value) ? Brightness.light : Brightness.dark,
      ),
    );

    update();
    Get.forceAppUpdate();
  }

  Future<void> saveAllColors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('primaryColor', primaryColor.value.toARGB32());
      await prefs.setInt('accentColor', accentColor.value.toARGB32());
      await prefs.setInt('textColor', textColor.value.toARGB32());
      await prefs.setInt('backgroundColor', backgroundColor.value.toARGB32());
      await prefs.setInt('drawerColor', drawerColor.value.toARGB32());
      await prefs.setInt('iconColor', iconColor.value.toARGB32());
      await prefs.setInt('currentSchemeIndex', currentSchemeIndex.value);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving colors: $e');
      }
    }
  }

  Future<void> saveColors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('iconColor', iconColor.value.toARGB32());
    } catch (e) {
      if (kDebugMode) {
        print('Error saving colors: $e');
      }
    }
  }

  ThemeData getLightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor.value,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor.value,
      canvasColor: backgroundColor.value,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: colorScheme.onSurface),
        bodyMedium: TextStyle(color: colorScheme.onSurface),
        titleLarge: TextStyle(color: colorScheme.onSurface),
      ).apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
    );
  }

  ThemeData getDarkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor.value,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor.value,
      canvasColor: backgroundColor.value,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: colorScheme.onSurface),
        bodyMedium: TextStyle(color: colorScheme.onSurface),
        titleLarge: TextStyle(color: colorScheme.onSurface),
      ).apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
    );
  }
}
