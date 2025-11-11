import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ColorController extends GetxController {
  static ColorController get to => Get.find();

  final Rx<MaterialColor> primaryColor = Colors.purple.obs;
  final Rx<Color> accentColor = Colors.deepOrange.obs;
  final Rx<Color> textColor = Colors.black.obs;
  final Rx<Color> backgroundColor = Colors.white.obs;
  final Rx<Color> drawerColor = Colors.purple.obs;
  final Rx<Color> iconColor = Colors.black.obs;

  final RxInt currentSchemeIndex = 0.obs;

  final List<Map<String, dynamic>> colorSchemes = [
    {
      'name': 'Default',
      'primary': Colors.blue,
      'accent': Colors.blueAccent,
      'text': Colors.black87,
      'background': Colors.white,
      'drawer': Colors.purple.shade900,
      'icon': Colors.deepOrange,
    },
    {
      'name': 'Ocean Blue',
      'primary': Colors.blue,
      'accent': Colors.amber,
      'text': Colors.black87,
      'background': Colors.white,
      'drawer': Colors.blue.shade900,
      'icon': Colors.amber,
    },
    {
      'name': 'Forest Green',
      'primary': Colors.teal,
      'accent': Colors.pink,
      'text': Colors.black,
      'background': Colors.white,
      'drawer': Colors.teal.shade900,
      'icon': Colors.pink,
    },
    {
      'name': 'Royal Purple',
      'primary': Colors.indigo,
      'accent': Colors.orange,
      'text': Colors.black87,
      'background': Colors.white,
      'drawer': Colors.indigo.shade900,
      'icon': Colors.orange,
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

    primaryColor.value = Colors.blue;
    accentColor.value = Colors.deepOrange;
    textColor.value = Colors.black;
    backgroundColor.value = Colors.white;
    drawerColor.value = Colors.purple;
    iconColor.value = Colors.green;

    loadColors();
  }

  Future<void> loadColors() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      primaryColor.value = getMaterialColor(
          Color(prefs.getInt('primaryColor') ?? Colors.blue.value));
      accentColor.value =
          Color(prefs.getInt('accentColor') ?? Colors.deepOrange.value);
      textColor.value = Color(prefs.getInt('textColor') ?? Colors.black.value);
      backgroundColor.value =
          Color(prefs.getInt('backgroundColor') ?? Colors.white.value);
      drawerColor.value =
          Color(prefs.getInt('drawerColor') ?? Colors.purple.value);
      iconColor.value = Color(prefs.getInt('iconColor') ?? Colors.green.value);

      update();
    } catch (e) {}
  }

  Future<void> setColorScheme(int index) async {
    try {
      if (index >= 0 && index < colorSchemes.length) {
        final scheme = colorSchemes[index];
        currentSchemeIndex.value = index;

        final primary = scheme['primary'];
        primaryColor.value = primary is MaterialColor
            ? primary
            : getMaterialColor(primary as Color);

        accentColor.value = scheme['accent'] as Color;
        textColor.value = scheme['text'] as Color;
        backgroundColor.value = scheme['background'] as Color;
        drawerColor.value = scheme['drawer'] as Color;
        iconColor.value = scheme['icon'] as Color;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('primaryColor', primaryColor.value.value);
        await prefs.setInt('accentColor', accentColor.value.value);
        await prefs.setInt('textColor', textColor.value.value);
        await prefs.setInt('backgroundColor', backgroundColor.value.value);
        await prefs.setInt('drawerColor', drawerColor.value.value);
        await prefs.setInt('iconColor', iconColor.value.value);
        await prefs.setInt('currentSchemeIndex', currentSchemeIndex.value);

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

  void updateIconColor(Color newColor) {
    try {
      iconColor.value = newColor;
      SharedPreferences.getInstance().then((prefs) {
        prefs.setInt('iconColor', newColor.value);
      });
      update(['iconColor']);
    } catch (e) {}
  }

  void updateDrawerColor(Color newColor) {
    try {
      drawerColor.value = newColor;
      SharedPreferences.getInstance().then((prefs) {
        prefs.setInt('drawerColor', newColor.value);
      });
      update();
    } catch (e) {}
  }

  void updateColors({
    Color? primary,
    Color? accent,
    Color? text,
    Color? background,
    Color? drawer,
    Color? icon,
  }) {
    if (primary != null) primaryColor.value = getMaterialColor(primary);
    if (accent != null) accentColor.value = accent;
    if (text != null) textColor.value = text;
    if (background != null) backgroundColor.value = background;
    if (drawer != null) updateDrawerColor(drawer);
    if (icon != null) updateIconColor(icon);

    update();
    Get.forceAppUpdate();
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
        surface: Colors.grey[900]!,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.grey[900],
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
      baseColor: const Color(0xFF2E2E2E),
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
