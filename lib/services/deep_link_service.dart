import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../controller/playlist_controller.dart';

class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // Handle initial link (app opened from closed state)
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }

      // Handle links while app is running
      _appLinks.uriLinkStream.listen((uri) {
        _handleDeepLink(uri);
      }, onError: (err) {
        if (kDebugMode) {
          print('Deep link error: $err');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing deep links: $e');
      }
    }
  }

  void _handleDeepLink(Uri uri) {
    if (kDebugMode) {
      print('Received deep link: $uri');
    }

    // Handle playlist deep links: fihirana://playlist/{playlistId}
    if (uri.scheme == 'fihirana' && uri.host == 'playlist') {
      final playlistId = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.first
          : uri.path.replaceAll('/', '');

      if (playlistId.isNotEmpty) {
        _importPlaylist(playlistId);
      }
    }
  }

  void _importPlaylist(String playlistId) {
    if (kDebugMode) {
      print('Importing playlist: $playlistId');
    }

    // Get the playlist controller and import the playlist
    try {
      final playlistController = Get.find<PlaylistController>();
      playlistController.importPlaylist(playlistId);
    } catch (e) {
      if (kDebugMode) {
        print('Error importing playlist: $e');
      }
    }
  }
}
