import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../controller/playlist_controller.dart';

class DynamicLinkService {
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // Handle initial link (app opened from closed state)
      final PendingDynamicLinkData? initialLink =
          await FirebaseDynamicLinks.instance.getInitialLink();
      if (initialLink != null) {
        _handleDynamicLink(initialLink);
      }

      // Handle links while app is running
      FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) {
        _handleDynamicLink(dynamicLinkData);
      }).onError((error) {
        if (kDebugMode) {
          print('Dynamic link error: $error');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing dynamic links: $e');
      }
    }
  }

  void _handleDynamicLink(PendingDynamicLinkData dynamicLinkData) {
    final Uri deepLink = dynamicLinkData.link;

    if (kDebugMode) {
      print('Received dynamic link: $deepLink');
    }

    // Handle playlist deep links: fihirana://playlist/{playlistId}
    if (deepLink.scheme == 'fihirana' && deepLink.host == 'playlist') {
      final playlistId = deepLink.pathSegments.isNotEmpty
          ? deepLink.pathSegments.first
          : deepLink.path.replaceAll('/', '');

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

  /// Create a Firebase Dynamic Link for playlist sharing
  static Future<String> createPlaylistLink(String playlistId) async {
    try {
      final DynamicLinkParameters parameters = DynamicLinkParameters(
        uriPrefix: 'https://fihirana.page.link',
        link: Uri.parse('fihirana://playlist/$playlistId'),
        androidParameters: const AndroidParameters(
          packageName: 'com.manasseh.fihirana_jff',
          minimumVersion: 1,
        ),
        socialMetaTagParameters: SocialMetaTagParameters(
          title: 'Fihirana Playlist',
          description: 'Check out this playlist on Fihirana!',
        ),
      );

      final ShortDynamicLink shortLink =
          await FirebaseDynamicLinks.instance.buildShortLink(parameters);

      return shortLink.shortUrl.toString();
    } catch (e) {
      if (kDebugMode) {
        print('Error creating dynamic link: $e');
      }
      // Fallback to custom scheme if dynamic link creation fails
      return 'fihirana://playlist/$playlistId';
    }
  }
}
