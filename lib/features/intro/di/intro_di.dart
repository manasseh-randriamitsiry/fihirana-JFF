import 'package:get/get.dart';
import 'package:fihirana/features/intro/presentation/controllers/splash_controller.dart';

/// Dependency injection for intro feature
class IntroDI {
  static const String _splashControllerTag = 'splashController';

  /// Initialize intro dependencies
  static void initialize() {
    // Controller
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
  }

  /// Reset intro dependencies (for testing)
  static void reset() {
    dispose();
    initialize();
  }
}