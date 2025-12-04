import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:fihirana/features/home/presentation/pages/home_screen.dart';
import 'language_selection_controller.dart';
import 'user_agreement_controller.dart';
import 'onboarding_auth_controller.dart';
import 'username_input_controller.dart';

class SplashController extends GetxController {
  static SplashController get to => Get.find();

  // Sub-controllers
  late final LanguageSelectionController _languageSelectionController;
  late final UserAgreementController _userAgreementController;
  late final OnboardingAuthController _onboardingAuthController;
  late final UsernameInputController _usernameInputController;

  // Getters for backward compatibility (UI still uses these)
  RxBool get agreementAccepted => _userAgreementController.agreementAccepted;
  RxBool get termsExpanded => _userAgreementController.termsExpanded;
  RxInt get currentPage => _languageSelectionController.currentPage;
  RxBool get isSigningIn => _onboardingAuthController.isSigningIn;
  RxString get googleUserName => _onboardingAuthController.googleUserName;
  RxString get googleUserEmail => _onboardingAuthController.googleUserEmail;
  Rx<Locale?> get selectedLocale => _languageSelectionController.selectedLocale;
  RxInt get usernameLength => _usernameInputController.usernameLength;
  TextEditingController get usernameController => _usernameInputController.usernameController;
  LiquidController get liquidController => _languageSelectionController.liquidController;

  @override
  void onInit() {
    super.onInit();
    _initializeSubControllers();
    _checkAgreementStatus();
  }

  void _initializeSubControllers() {
    _languageSelectionController = Get.find<LanguageSelectionController>();
    _userAgreementController = Get.find<UserAgreementController>();
    _onboardingAuthController = Get.find<OnboardingAuthController>();
    _usernameInputController = Get.find<UsernameInputController>();
  }

  // Delegate to sub-controllers
  bool get isGoogleUserSignedIn => _onboardingAuthController.isGoogleUserSignedIn;

  Future<void> selectLanguage(Locale locale) async {
    HapticFeedback.selectionClick();
    await _languageSelectionController.selectLanguage(locale);
  }

  Future<void> handleGoogleSignIn() async {
    HapticFeedback.mediumImpact();
    await _onboardingAuthController.handleGoogleSignIn();
  }

  Future<void> handleUsernameSubmit() async {
    HapticFeedback.mediumImpact();

    // Validate username using sub-controller
    final validationError = _usernameInputController.validateUsername(_usernameInputController.usernameController.text);
    if (validationError != null) {
      Get.snackbar(
        'Error',
        validationError,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    try {
      // Save agreement status
      await _userAgreementController.saveAgreementStatus();

      // Submit username
      await _usernameInputController.submitUsername();

      if (kDebugMode) {
        final username = _usernameInputController.usernameController.text.trim();
        print('✅ Splash: Saved username to SharedPreferences: $username');
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Name not saved',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> handleGoogleUserContinue() async {
    HapticFeedback.mediumImpact();
    await _onboardingAuthController.handleGoogleUserContinue();
  }

  String getContinueButtonText(String continueAs, String continueAsGuest) {
    if (isGoogleUserSignedIn && _onboardingAuthController.googleUserName.value.isNotEmpty) {
      return continueAs;
    } else {
      final username = _usernameInputController.usernameController.text.trim();
      if (username.isNotEmpty) {
        return continueAs;
      } else {
        return continueAsGuest;
      }
    }
  }

  Future<void> _checkAgreementStatus() async {
    final hasAgreed = await _userAgreementController.hasAgreedToTerms();
    final username = _usernameInputController.usernameController.text.trim();
    final hasSelectedLanguage = _languageSelectionController.selectedLocale.value != null;

    if (hasAgreed && username.isNotEmpty && hasSelectedLanguage) {
      Get.offAll(() => const HomeScreen());
    }
  }

  void updatePage(int page) {
    _languageSelectionController.updatePage(page);
  }

  void toggleAgreement() {
    _userAgreementController.toggleAgreement();
  }

  void toggleTermsExpanded() {
    _userAgreementController.toggleTermsExpanded();
  }
}

