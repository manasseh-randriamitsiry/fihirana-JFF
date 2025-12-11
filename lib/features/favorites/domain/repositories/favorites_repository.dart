import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/favorites/domain/entities/favorite.dart';

/// Repository interface for favorites operations
abstract class FavoritesRepository {
  /// Get stream of favorite hymns
  Stream<List<Hymn>> getFavoriteHymnsStream();

  /// Toggle favorite status for a hymn
  Future<void> toggleFavorite(Hymn hymn);

  /// Check if audio is available for a hymn
  Future<bool> checkAudioAvailability(String hymnId);

  /// Check if hymn is currently playing
  bool isHymnPlaying(String hymnId);

  /// Get all favorites (for admin purposes)
  Future<List<Favorite>> getAllFavorites();

  /// Stream all favorites
  Stream<List<Favorite>> streamAllFavorites();
}