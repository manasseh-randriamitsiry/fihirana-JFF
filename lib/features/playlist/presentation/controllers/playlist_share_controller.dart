import 'dart:convert';
import 'package:get/get.dart';
import 'package:fihirana/features/playlist/domain/entities/playlist.dart';
import 'package:fihirana/features/playlist/data/services/playlist_service.dart';
import 'package:fihirana/core/error/error_handler.dart';

/// Controller for managing playlist sharing and export operations
class PlaylistShareController extends GetxController {
  final PlaylistService _playlistService;

  PlaylistShareController({required PlaylistService playlistService})
      : _playlistService = playlistService;

  final RxBool isSharing = false.obs;

  Future<String> exportPlaylistToJson(String playlistId) async {
    try {
      isSharing.value = true;
      final playlist = await _playlistService.getPlaylistById(playlistId);
      if (playlist != null) {
        return json.encode(playlist.toJson());
      }
      throw Exception('Playlist not found');
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorExportingPlaylist'.tr);
      rethrow;
    } finally {
      isSharing.value = false;
    }
  }

  Future<String> sharePlaylist(String playlistId) async {
    try {
      isSharing.value = true;
      // Create a shareable link using GitHub Pages
      return 'https://manasseh-randriamitsiry.github.io/fihirana-share/?id=$playlistId';
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorSharingPlaylist'.tr);
      rethrow;
    } finally {
      isSharing.value = false;
    }
  }

  Future<void> importPlaylistFromJson(String jsonContent) async {
    try {
      isSharing.value = true;
      final Map<String, dynamic> jsonMap = json.decode(jsonContent);
      final playlist = Playlist.fromJson(jsonMap);

      // Create new playlist with "(Imported)" suffix
      await _playlistService.createPlaylist(
        '${playlist.title} (Imported)',
        playlist.date,
      );
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorImportingPlaylist'.tr);
    } finally {
      isSharing.value = false;
    }
  }

  Future<void> importPlaylistFromSharedLink(String sharedLink) async {
    try {
      isSharing.value = true;
      // Extract playlist ID from shared link
      final uri = Uri.parse(sharedLink);
      final playlistId = uri.queryParameters['id'];

      if (playlistId != null) {
        final playlist = await _playlistService.getPlaylistById(playlistId);
        if (playlist != null) {
          await _playlistService.createPlaylist(
            '${playlist.title} (Imported)',
            playlist.date,
          );
        }
      }
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorImportingPlaylist'.tr);
    } finally {
      isSharing.value = false;
    }
  }
}
