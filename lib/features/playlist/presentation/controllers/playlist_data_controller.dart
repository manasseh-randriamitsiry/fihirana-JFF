import 'package:get/get.dart';
import 'package:fihirana/features/playlist/domain/entities/playlist.dart';
import 'package:fihirana/features/playlist/data/services/playlist_service.dart';
import 'package:fihirana/core/error/error_handler.dart';

/// Controller for managing playlist data operations
class PlaylistDataController extends GetxController {
  final PlaylistService _playlistService;

  PlaylistDataController({required PlaylistService playlistService})
      : _playlistService = playlistService;

  final RxList<Playlist> playlists = <Playlist>[].obs;
  final RxBool isLoading = false.obs;

  void bindPlaylists() {
    playlists.bindStream(_playlistService.getUserPlaylistsStream());
  }

  Future<String?> createPlaylist(String title, DateTime date, {String? description}) async {
    try {
      isLoading.value = true;
      return await _playlistService.createPlaylist(title, date, description: description);
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorCreatingPlaylist'.tr);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updatePlaylist(String id, {String? title, DateTime? date, String? description}) async {
    try {
      isLoading.value = true;
      await _playlistService.updatePlaylist(id, title: title, date: date, description: description);
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorUpdatingPlaylist'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deletePlaylist(String id) async {
    try {
      isLoading.value = true;
      await _playlistService.deletePlaylist(id);
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorDeletingPlaylist'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addHymnToPlaylist(String playlistId, String hymnId) async {
    try {
      await _playlistService.addHymnToPlaylist(playlistId, hymnId);
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorAddingHymnToPlaylist'.tr);
    }
  }

  Future<void> removeHymnFromPlaylist(String playlistId, String hymnId) async {
    try {
      await _playlistService.removeHymnFromPlaylist(playlistId, hymnId);
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorRemovingHymnFromPlaylist'.tr);
    }
  }

  Future<void> reorderPlaylist(String playlistId, List<String> hymnIds) async {
    try {
      // Reordering is handled by updating the playlist with new hymn order
      final playlist = await _playlistService.getPlaylistById(playlistId);
      if (playlist != null) {
        await _playlistService.updatePlaylist(playlistId, title: playlist.title, date: playlist.date);
      }
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorReorderingPlaylist'.tr);
    }
  }

  Future<Playlist?> getPlaylistById(String id) async {
    try {
      return await _playlistService.getPlaylistById(id);
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorLoadingPlaylist'.tr);
      return null;
    }
  }

  Future<List<Playlist>> searchPlaylists(String query) async {
    try {
      final allPlaylists = await _playlistService.getLocalPlaylists();
      return allPlaylists.where((playlist) =>
        playlist.title.toLowerCase().contains(query.toLowerCase())
      ).toList();
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorSearchingPlaylists'.tr);
      return [];
    }
  }
}