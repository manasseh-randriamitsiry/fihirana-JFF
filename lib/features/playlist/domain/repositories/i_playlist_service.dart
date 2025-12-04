import 'package:fihirana/features/playlist/domain/entities/playlist.dart';

abstract class IPlaylistService {
  Future<List<Playlist>> getLocalPlaylists();
  Future<void> saveLocalPlaylists(List<Playlist> playlists);
  Future<String?> createPlaylist(String title, DateTime date, {String? description});
  Stream<List<Playlist>> getUserPlaylistsStream();
  void notifyPlaylistsChanged();
  Future<Playlist?> getPlaylistById(String id);
  Future<bool> addHymnToPlaylist(String playlistId, String hymnId);
  Future<bool> removeHymnFromPlaylist(String playlistId, String hymnId);
  Future<bool> deletePlaylist(String playlistId);
  Future<bool> updatePlaylist(String playlistId, {String? title, String? description, DateTime? date});
  Future<void> syncPlaylistsToFirebase();
  Future<void> resetSyncStatus();
}