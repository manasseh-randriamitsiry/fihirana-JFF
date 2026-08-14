import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fihirana/core/localization/language_controller.dart';

/// Controller for language selection during onboarding
class LanguageSelectionController extends GetxController {
  final LanguageController _languageController = Get.find<LanguageController>();
  late final PageController _pageController;

  final Rx<Locale?> selectedLocale = Rx<Locale?>(null);
  final RxInt currentPage = 0.obs;

  @override
  void onInit() {
    super.onInit();
    selectedLocale.value = _languageController.currentLocaleValue;
    _pageController = PageController();
  }

  /// Select language and proceed to next page
  Future<void> selectLanguage(Locale locale) async {
    selectedLocale.value = locale;
    _languageController.changeLanguage(locale);

    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', locale.languageCode);
  }

  /// Update current page index
  void updatePage(int page) {
    currentPage.value = page;
  }

  PageController get pageController => _pageController;

  Future<void> goToPage(int page) async {
    if (!_pageController.hasClients) return;
    await _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  void onClose() {
    _pageController.dispose();
    super.onClose();
  }
}
