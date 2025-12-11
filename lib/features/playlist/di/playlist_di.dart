import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fihirana/features/playlist/presentation/controllers/playlist_controller.dart';
import 'package:fihirana/features/playlist/data/services/playlist_service.dart';

/// Dependency injection for playlist feature
class PlaylistDI {
  static const String _playlistControllerTag = 'playlistController';

  /// Initialize playlist dependencies
  static void initialize() {
    // Services
    Get.lazyPut<SharedPreferences>(
      () => throw UnimplementedError('SharedPreferences should be initialized globally'),
    );
    Get.lazyPut<FirebaseAuth>(
      () => FirebaseAuth.instance,
    );

    // Playlist Service
    Get.lazyPut<PlaylistService>(
      () => PlaylistService(),
    );

    // Controller
    Get.lazyPut<PlaylistController>(
      () => PlaylistController(
        playlistService: Get.find<PlaylistService>(),
        auth: Get.find<FirebaseAuth>(),
      ),
      tag: _playlistControllerTag,
    );

    // Also register without tag for backward compatibility
    Get.lazyPut<PlaylistController>(
      () => PlaylistController(
        playlistService: Get.find<PlaylistService>(),
        auth: Get.find<FirebaseAuth>(),
      ),
    );
  }

  /// Get playlist controller
  static PlaylistController get playlistController {
    try {
      return Get.find<PlaylistController>(tag: _playlistControllerTag);
    } catch (e) {
      // Fallback to untagged version
      return Get.find<PlaylistController>();
    }
  }

  /// Dispose playlist dependencies
  static void dispose() {
    Get.delete<PlaylistController>(tag: _playlistControllerTag);
    Get.delete<PlaylistController>(); // Also delete untagged version
    Get.delete<PlaylistService>();
    Get.delete<FirebaseAuth>();
    Get.delete<SharedPreferences>();
  }

  /// Reset playlist dependencies (for testing)
  static void reset() {
    dispose();
    initialize();
  }
}