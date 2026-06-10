import 'package:get/get.dart';
import 'package:fihirana/features/playlist/data/services/playlist_service.dart';
import 'package:fihirana/core/error/error_handler.dart';

/// Controller for managing playlist synchronization
class PlaylistSyncController extends GetxController {
  final PlaylistService _playlistService;

  PlaylistSyncController({required PlaylistService playlistService})
      : _playlistService = playlistService;

  final RxBool isSyncing = false.obs;

  Future<void> syncPlaylistsToFirebase() async {
    try {
      isSyncing.value = true;
      await _playlistService.syncPlaylistsToFirebase();
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorSyncingPlaylists'.tr);
    } finally {
      isSyncing.value = false;
    }
  }

  Future<void> syncPlaylistsFromFirebase() async {
    try {
      isSyncing.value = true;
      // Sync from Firebase is handled by the service automatically
      // Just trigger a rebind of the playlists stream
      await _playlistService.syncPlaylistsToFirebase();
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorSyncingPlaylists'.tr);
    } finally {
      isSyncing.value = false;
    }
  }

  void resetSyncStatus() {
    _playlistService.resetSyncStatus();
  }
}
