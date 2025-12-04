import 'package:get/get.dart';
import 'package:fihirana/features/home/presentation/controllers/home_controller.dart';

/// Dependency injection for home feature
class HomeDI {
  static const String _homeControllerTag = 'homeController';

  /// Initialize home dependencies
  static void initialize() {
    // Controller
    Get.lazyPut<HomeController>(
      () => HomeController(),
      tag: _homeControllerTag,
    );
  }

  /// Get home controller
  static HomeController get homeController {
    return Get.find<HomeController>(tag: _homeControllerTag);
  }

  /// Dispose home dependencies
  static void dispose() {
    Get.delete<HomeController>(tag: _homeControllerTag);
  }

  /// Reset home dependencies (for testing)
  static void reset() {
    dispose();
    initialize();
  }
}