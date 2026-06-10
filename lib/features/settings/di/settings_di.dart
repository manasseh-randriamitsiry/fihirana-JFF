import 'package:get/get.dart';
import 'package:fihirana/features/settings/presentation/controllers/settings_controller.dart';

/// Dependency injection for settings feature
class SettingsDI {
  static const String _settingsControllerTag = 'settingsController';

  /// Initialize settings dependencies
  static void initialize() {
    // Controller
    Get.lazyPut<SettingsController>(
      () => SettingsController(),
      tag: _settingsControllerTag,
    );
  }

  /// Get settings controller
  static SettingsController get settingsController {
    return Get.find<SettingsController>(tag: _settingsControllerTag);
  }

  /// Dispose settings dependencies
  static void dispose() {
    Get.delete<SettingsController>(tag: _settingsControllerTag);
  }

  /// Reset settings dependencies (for testing)
  static void reset() {
    dispose();
    initialize();
  }
}
