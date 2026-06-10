import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fihirana/features/playlist/domain/entities/playlist.dart';
import 'package:fihirana/features/playlist/data/services/playlist_service.dart';
import 'package:fihirana/features/playlist/presentation/controllers/playlist_data_controller.dart';
import 'package:fihirana/features/playlist/presentation/controllers/playlist_share_controller.dart';
import 'package:fihirana/features/playlist/presentation/controllers/playlist_sync_controller.dart';
import 'package:fihirana/core/error/error_handler.dart';

class PlaylistController extends GetxController {
  final PlaylistService _playlistService;
  final FirebaseAuth _auth;

  // Sub-controllers for different concerns
  late final PlaylistDataController dataController;
  late final PlaylistShareController shareController;
  late final PlaylistSyncController syncController;

  PlaylistController({
    required PlaylistService playlistService,
    FirebaseAuth? auth,
  })  : _playlistService = playlistService,
        _auth = auth ?? FirebaseAuth.instance {
    // Initialize sub-controllers
    dataController = Get.put(PlaylistDataController(
      playlistService: _playlistService,
    ));

    shareController = Get.put(PlaylistShareController(
      playlistService: _playlistService,
    ));

    syncController = Get.put(PlaylistSyncController(
      playlistService: _playlistService,
    ));
  }

  // Delegate properties for backward compatibility
  RxList<Playlist> get playlists => dataController.playlists;
  RxBool get isLoading => dataController.isLoading;
  RxBool get isSharing => shareController.isSharing;
  RxBool get isSyncing => syncController.isSyncing;

  @override
  void onInit() {
    super.onInit();
    dataController.bindPlaylists();
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // User logged in, sync local playlists to Firebase
        syncController.syncPlaylistsToFirebase();
      } else {
        // User logged out, reset sync status
        syncController.resetSyncStatus();
      }
      // Rebind to refresh the stream
      dataController.bindPlaylists();
    });
  }

  void bindPlaylists() {
    dataController.bindPlaylists();
  }

  // Delegate methods to sub-controllers
  Future<String?> createPlaylist(String title, DateTime date) async {
    return await dataController.createPlaylist(title, date);
  }

  Future<void> updatePlaylist(String id, String title, DateTime date) async {
    await dataController.updatePlaylist(id, title: title, date: date);
  }

  Future<void> deletePlaylist(String id) async {
    await dataController.deletePlaylist(id);
  }

  Future<void> addHymnToPlaylist(String playlistId, String hymnId) async {
    await dataController.addHymnToPlaylist(playlistId, hymnId);
  }

  Future<void> removeHymnFromPlaylist(String playlistId, String hymnId) async {
    await dataController.removeHymnFromPlaylist(playlistId, hymnId);
  }

  Future<void> reorderPlaylist(String playlistId, List<String> hymnIds) async {
    await dataController.reorderPlaylist(playlistId, hymnIds);
  }

  Future<Playlist?> getPlaylistById(String id) async {
    return await dataController.getPlaylistById(id);
  }

  Future<List<Playlist>> searchPlaylists(String query) async {
    return await dataController.searchPlaylists(query);
  }

  Future<void> sharePlaylist(String playlistId) async {
    try {
      final sharedLink = await shareController.sharePlaylist(playlistId);
      await SharePlus.instance.share(
        ShareParams(text: sharedLink, subject: 'playlistShared'.tr),
      );
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorSharingPlaylist'.tr);
    }
  }

  Future<void> exportPlaylist(String playlistId) async {
    try {
      final jsonContent =
          await shareController.exportPlaylistToJson(playlistId);
      await SharePlus.instance.share(
        ShareParams(text: jsonContent, subject: 'playlistExported'.tr),
      );
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorExportingPlaylist'.tr);
    }
  }

  Future<void> importPlaylistFromJson(String jsonContent) async {
    await shareController.importPlaylistFromJson(jsonContent);
  }

  Future<void> importPlaylistFromSharedLink(String sharedLink) async {
    await shareController.importPlaylistFromSharedLink(sharedLink);
  }

  Future<void> importPlaylist(String playlistId) async {
    try {
      isLoading.value = true;
      final playlist = await dataController.getPlaylistById(playlistId);

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
          // Skip duplicate import silently for deep links
          return;
        }

        // Create new playlist with imported title
        await dataController.createPlaylist(
          '${playlist.title} (Imported)',
          playlist.date,
          description: playlist.description,
        );
      }
    } catch (e) {
      // Handle error silently for deep links
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> syncPlaylistsToFirebase() async {
    await syncController.syncPlaylistsToFirebase();
  }

  Future<void> syncPlaylistsFromFirebase() async {
    await syncController.syncPlaylistsFromFirebase();
  }

  void resetSyncStatus() {
    syncController.resetSyncStatus();
  }

  Future<void> updatePlaylistDate(String playlistId, DateTime date) async {
    await dataController.updatePlaylist(playlistId, date: date);
  }
}
