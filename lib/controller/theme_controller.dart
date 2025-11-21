import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  var isDarkMode = false.obs;
  var isAutoTheme = true.obs; // Auto-theme enabled by default

  @override
  void onInit() {
    super.onInit();
    loadThemeFromPrefs();

    // Listen to system theme changes
    SchedulerBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
        () {
      if (isAutoTheme.value) {
        _applySystemTheme();
      }
    };
  }

  Future<void> loadThemeFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    isAutoTheme.value = prefs.getBool('isAutoTheme') ?? true;

    if (isAutoTheme.value) {
      _applySystemTheme();
    } else {
      isDarkMode.value = prefs.getBool('isDarkMode') ?? true;
      Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
    }
  }

  void _applySystemTheme() {
    final brightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;
    isDarkMode.value = brightness == Brightness.dark;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  void toggleTheme() async {
    // Manual toggle disables auto-theme
    isAutoTheme.value = false;
    isDarkMode.value = !isDarkMode.value;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAutoTheme', false);
    await prefs.setBool('isDarkMode', isDarkMode.value);
  }

  void setAutoTheme(bool enabled) async {
    isAutoTheme.value = enabled;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAutoTheme', enabled);

    if (enabled) {
      _applySystemTheme();
    }
  }
}
