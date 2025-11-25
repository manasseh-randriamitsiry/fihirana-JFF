import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../models/playlist.dart';
import '../services/playlist_service.dart';
import '../services/security_service.dart';
import '../services/google_drive_service.dart';

class PlaylistController extends GetxController {
  final PlaylistService _playlistService = PlaylistService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxList<Playlist> playlists = <Playlist>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    bindPlaylists();
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // User logged in, sync local playlists to Firebase
        _playlistService.syncPlaylistsToFirebase();
      } else {
        // User logged out, reset sync status
        _playlistService.resetSyncStatus();
      }
      // Rebind to refresh the stream
      bindPlaylists();
    });
  }

  void bindPlaylists() {
    playlists.bindStream(_playlistService.getUserPlaylistsStream());
  }

  Future<String?> createPlaylist(String title, DateTime date) async {
    try {
      isLoading.value = true;
      final id = await _playlistService.createPlaylist(title, date);
      Get.snackbar(
        'Success',
        'Playlist created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return id;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create playlist',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updatePlaylistDate(String playlistId, DateTime newDate) async {
    final success =
        await _playlistService.updatePlaylist(playlistId, date: newDate);
    if (success) {
      Get.snackbar(
        'Success',
        'Playlist date updated',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        'Failed to update playlist date',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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
    // Security check first
    final SecurityService securityService = SecurityService.instance;
    
    // Check if user is authenticated via Firebase
    final isFirebaseAuthenticated = FirebaseAuth.instance.currentUser != null;
    
    // Check if user is authenticated via Google Drive (need to get drive service)
    final GoogleDriveService driveService = GoogleDriveService();
    final isGoogleDriveAuthenticated = driveService.currentUser != null;
    
    if (!isFirebaseAuthenticated && !isGoogleDriveAuthenticated) {
      // Guest user - block sharing for guests to prevent abuse
      if (kDebugMode) {
        print('🚫 Guest user attempted to share playlist');
      }
      Get.snackbar(
        'Authentication Required',
        'Please sign in to access sharing features.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
      return;
    }
    
    // Check Firebase user security if authenticated via Firebase
    if (isFirebaseAuthenticated) {
      await securityService.checkUserSecurity();
      if (securityService.isUserBlocked) {
        if (kDebugMode) {
          print('🚫 Blocked Firebase user attempted to share playlist');
        }
        Get.snackbar(
          'Access Denied',
          'Your account has been restricted. Sharing features are not available.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
        return;
      }
    }
    
    // Check Google Drive user email if authenticated via Google Drive
    if (isGoogleDriveAuthenticated) {
      final googleUserEmail = driveService.currentUser?.email;
      if (googleUserEmail != null) {
        final isEmailBlocked = await securityService.isEmailBlocked(googleUserEmail);
        if (isEmailBlocked) {
          if (kDebugMode) {
            print('🚫 Blocked Google Drive user attempted to share playlist: $googleUserEmail');
          }
          Get.snackbar(
            'Access Denied',
            'Your account has been restricted. Sharing features are not available.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 5),
          );
          return;
        }
      }
    }
    
    // Create a clickable HTTPS link using GitHub Pages
    final shareUrl =
        'https://manasseh-randriamitsiry.github.io/fihirana-share/?id=${playlist.id}';
    final String text =
        'Check out my playlist "${playlist.title}" for ${playlist.date.toString().split(' ')[0]}!\n\n'
        'Tap to open in Fihirana app:\n$shareUrl\n\n'
        'Or manually import using ID: ${playlist.id}';

    await Share.share(text);
  }

  Future<void> importPlaylist(String playlistId) async {
    try {
      isLoading.value = true;
      final playlist = await _playlistService.getPlaylistById(playlistId);

      if (playlist != null) {
        // Check for duplicates
        final isDuplicate = playlists.any((p) {
          // Check if title matches (either original or imported version)
          final titleMatches = p.title == playlist.title ||
              p.title == '${playlist.title} (Imported)';

          // Check if content matches (same hymns)
          final contentMatches = p.hymnIds.length == playlist.hymnIds.length &&
              p.hymnIds.toSet().containsAll(playlist.hymnIds);

          return titleMatches && contentMatches;
        });

        if (isDuplicate) {
          Get.snackbar(
            'Info',
            'Playlist "${playlist.title}" already exists',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.blue,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
          return;
        }

        // Create a new playlist with the imported title
        final newPlaylistId = await _playlistService.createPlaylist(
          '${playlist.title} (Imported)',
          playlist.date,
        );

        // Add all hymns from the original playlist to the new one
        if (newPlaylistId != null && playlist.hymnIds.isNotEmpty) {
          for (final hymnId in playlist.hymnIds) {
            await _playlistService.addHymnToPlaylist(newPlaylistId, hymnId);
          }
        }

        Get.snackbar(
          'Success',
          'Playlist "${playlist.title}" imported with ${playlist.hymnIds.length} hymns',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
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
        'Failed to import playlist: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
