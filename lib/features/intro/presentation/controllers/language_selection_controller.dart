import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:fihirana/core/localization/language_controller.dart';

/// Controller for language selection during onboarding
class LanguageSelectionController extends GetxController {
  final LanguageController _languageController = Get.find<LanguageController>();
  late final LiquidController _liquidController;

  final Rx<Locale?> selectedLocale = Rx<Locale?>(null);
  final RxInt currentPage = 0.obs;

  @override
  void onInit() {
    super.onInit();
    selectedLocale.value = _languageController.currentLocaleValue;
    _liquidController = LiquidController();
  }

  /// Select language and proceed to next page
  Future<void> selectLanguage(Locale locale) async {
    selectedLocale.value = locale;
    _languageController.changeLanguage(locale);

    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', locale.languageCode);

    // Animate to next page
    await _liquidController.animateToPage(page: 1, duration: 600);
  }

  /// Update current page index
  void updatePage(int page) {
    currentPage.value = page;
  }

  /// Get liquid controller for page animations
  LiquidController get liquidController => _liquidController;
}