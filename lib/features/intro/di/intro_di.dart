import 'package:get/get.dart';
import 'package:fihirana/features/intro/presentation/controllers/splash_controller.dart';
import 'package:fihirana/features/intro/presentation/controllers/language_selection_controller.dart';
import 'package:fihirana/features/intro/presentation/controllers/user_agreement_controller.dart';
import 'package:fihirana/features/intro/presentation/controllers/onboarding_auth_controller.dart';
import 'package:fihirana/features/intro/presentation/controllers/username_input_controller.dart';

/// Dependency injection for intro feature
class IntroDI {
  static const String _splashControllerTag = 'splashController';

  /// Initialize intro dependencies
  static void initialize() {
    // Sub-controllers
    Get.lazyPut<LanguageSelectionController>(() => LanguageSelectionController());
    Get.lazyPut<UserAgreementController>(() => UserAgreementController());
    Get.lazyPut<OnboardingAuthController>(() => OnboardingAuthController());
    Get.lazyPut<UsernameInputController>(() => UsernameInputController());

    // Main controller
    Get.lazyPut<SplashController>(
      () => SplashController(),
      tag: _splashControllerTag,
    );
  }

  /// Get splash controller
  static SplashController get splashController {
    return Get.find<SplashController>(tag: _splashControllerTag);
  }

  /// Dispose intro dependencies
  static void dispose() {
    Get.delete<SplashController>(tag: _splashControllerTag);
    Get.delete<UsernameInputController>();
    Get.delete<OnboardingAuthController>();
    Get.delete<UserAgreementController>();
    Get.delete<LanguageSelectionController>();
  }

  /// Reset intro dependencies (for testing)
  static void reset() {
    dispose();
    initialize();
  }
}