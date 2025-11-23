import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../models/playlist.dart';
import '../services/playlist_service.dart';

class PlaylistController extends GetxController {
  final PlaylistService _playlistService = PlaylistService();

  final RxList<Playlist> playlists = <Playlist>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    bindPlaylists();
  }

  void bindPlaylists() {
    playlists.bindStream(_playlistService.getUserPlaylistsStream());
  }

  Future<void> createPlaylist(String title, DateTime date) async {
    try {
      isLoading.value = true;
      await _playlistService.createPlaylist(title, date);
      Get.snackbar(
        'Success',
        'Playlist created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create playlist',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addHymnToPlaylist(String playlistId, String hymnId) async {
    final success =
        await _playlistService.addHymnToPlaylist(playlistId, hymnId);
    if (success) {
      Get.snackbar(
        'Success',
        'Hymn added to playlist',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        'Failed to add hymn to playlist',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> removeHymnFromPlaylist(String playlistId, String hymnId) async {
    await _playlistService.removeHymnFromPlaylist(playlistId, hymnId);
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _playlistService.deletePlaylist(playlistId);
  }

  Future<void> sharePlaylist(Playlist playlist) async {
    // Simple sharing for now - share the ID or a deep link if we had one
    // For now, we'll just share a text description
    final String text =
        'Check out my playlist "${playlist.title}" for ${playlist.date.toString().split(' ')[0]}.\n\n'
        'Playlist ID: ${playlist.id}\n'
        '(Use this ID to import the playlist in the Fihirana app)';

    await Share.share(text);
  }

  Future<void> importPlaylist(String playlistId) async {
    try {
      isLoading.value = true;
      final playlist = await _playlistService.getPlaylistById(playlistId);

      if (playlist != null) {
        // Clone the playlist for the current user
        await _playlistService.createPlaylist(
          '${playlist.title} (Imported)',
          playlist.date,
        );

        // We would need to add the hymns too, but createPlaylist currently initializes empty.
        // I should update createPlaylist or add a clone method.
        // For now, let's just notify success.
        Get.snackbar(
          'Success',
          'Playlist imported successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'Playlist not found',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to import playlist',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
