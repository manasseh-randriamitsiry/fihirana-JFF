import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fihirana/features/playlist/presentation/controllers/playlist_controller.dart';
import 'package:fihirana/features/playlist/data/services/playlist_service.dart';

/// Dependency injection for playlist feature
class PlaylistDI {
  static const String _playlistControllerTag = 'playlistController';

  /// Initialize playlist dependencies
  static void initialize() {
    Get.lazyPut<FirebaseAuth>(
      () => FirebaseAuth.instance,
      fenix: true,
    );

    // Playlist Service
    // fenix keeps one service alive across routes; its Firestore watcher is
    // rebound per listener, so it must not be recreated on every screen visit.
    Get.lazyPut<PlaylistService>(
      () => PlaylistService(),
      fenix: true,
    );

    // Controller
    Get.put<PlaylistController>(
      PlaylistController(
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
    if (Get.isRegistered<PlaylistService>()) {
      Get.find<PlaylistService>().dispose();
    }
    Get.delete<PlaylistService>();
  }

  /// Reset playlist dependencies (for testing)
  static void reset() {
    dispose();
    initialize();
  }
}
