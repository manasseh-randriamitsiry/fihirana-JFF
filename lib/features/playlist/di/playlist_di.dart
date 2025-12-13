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
  }

  /// Get playlist controller
  static PlaylistController get playlistController {
    return Get.find<PlaylistController>(tag: _playlistControllerTag);
  }

  /// Dispose playlist dependencies
  static void dispose() {
    Get.delete<PlaylistController>(tag: _playlistControllerTag);
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