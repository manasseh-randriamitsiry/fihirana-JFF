import 'package:fihirana/features/hymn/domain/entities/hymn.dart';

/// Abstract interface for Hymn service operations
/// This allows for dependency injection and better testability
abstract class IHymnService {
  /// Get all hymns
  Future<List<Hymn>> getAllHymns();

  /// Get hymn by ID
  Future<Hymn?> getHymnById(String id);

  /// Get hymn by title
  Future<Hymn?> getHymnByTitle(String title);

  /// Search hymns by text content
  Future<List<Hymn>> searchHymns(String query);

  /// Get hymns by category
  Future<List<Hymn>> getHymnsByCategory(String category);

  /// Get hymns by author
  Future<List<Hymn>> getHymnsByAuthor(String author);

  /// Get favorite hymns
  Future<List<Hymn>> getFavoriteHymns();

  /// Add hymn to favorites
  Future<void> addToFavorites(String hymnId);

  /// Remove hymn from favorites
  Future<void> removeFromFavorites(String hymnId);

  /// Check if hymn is favorite
  Future<bool> isFavorite(String hymnId);

  /// Get random hymn
  Future<Hymn?> getRandomHymn();

  /// Get hymns for a specific number range
  Future<List<Hymn>> getHymnsByNumberRange(int start, int end);

  /// Get total number of hymns
  Future<int> get hymnCount;

  /// Get all categories
  Future<List<String>> getCategories();

  /// Get all authors
  Future<List<String>> getAuthors();

  /// Initialize the service
  Future<void> initialize();

  /// Refresh hymn data
  Future<void> refresh();

  /// Clear cache (for testing purposes)
  void clearCache();

  /// Export hymns data
  Future<Map<String, dynamic>> exportData();

  /// Import hymns data
  Future<void> importData(Map<String, dynamic> data);
}
