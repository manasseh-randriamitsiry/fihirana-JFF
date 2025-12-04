import 'package:get/get.dart';
import 'package:fihirana/features/playlist/presentation/controllers/playlist_controller.dart';

/// Dependency injection for playlist feature
class PlaylistDI {
  static const String _playlistControllerTag = 'playlistController';

  /// Initialize playlist dependencies
  static void initialize() {
    // Controller
    Get.lazyPut<PlaylistController>(
      () => PlaylistController(),
      tag: _playlistControllerTag,
    );
  }

  /// Get playlist controller
  static PlaylistController get playlistController {
    return Get.find<PlaylistController>(tag: _playlistControllerTag);
  }

  /// Dispose playlist dependencies
  static void dispose() {
    Get.delete<PlaylistController>(tag: _playlistControllerTag);
  }

  /// Reset playlist dependencies (for testing)
  static void reset() {
    dispose();
    initialize();
  }
}