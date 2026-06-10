import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/hymn/domain/repositories/hymn_repository.dart';
import 'package:fihirana/features/hymn/data/services/hymn_service.dart';

class HymnRepositoryImpl implements IHymnService {
  final HymnService _hymnService;

  HymnRepositoryImpl(this._hymnService);

  @override
  Future<List<Hymn>> getAllHymns() {
    return _hymnService.getAllHymns();
  }

  @override
  Future<Hymn?> getHymnById(String id) {
    return _hymnService.getHymnById(id);
  }

  @override
  Future<Hymn?> getHymnByTitle(String title) {
    return _hymnService.getHymnByTitle(title);
  }

  @override
  Future<List<Hymn>> searchHymns(String query) {
    return _hymnService.searchHymns(query);
  }

  @override
  Future<List<Hymn>> getHymnsByCategory(String category) {
    return _hymnService.getHymnsByCategory(category);
  }

  @override
  Future<List<Hymn>> getHymnsByAuthor(String author) {
    return _hymnService.getHymnsByAuthor(author);
  }

  @override
  Future<List<Hymn>> getFavoriteHymns() {
    return _hymnService.getFavoriteHymns();
  }

  @override
  Future<void> addToFavorites(String hymnId) {
    return _hymnService.addToFavorites(hymnId);
  }

  @override
  Future<void> removeFromFavorites(String hymnId) {
    return _hymnService.removeFromFavorites(hymnId);
  }

  @override
  Future<bool> isFavorite(String hymnId) {
    return _hymnService.isFavorite(hymnId);
  }

  @override
  Future<Hymn?> getRandomHymn() {
    return _hymnService.getRandomHymn();
  }

  @override
  Future<List<Hymn>> getHymnsByNumberRange(int start, int end) {
    return _hymnService.getHymnsByNumberRange(start, end);
  }

  @override
  Future<int> get hymnCount {
    return _hymnService.hymnCount;
  }

  @override
  Future<List<String>> getCategories() {
    return _hymnService.getCategories();
  }

  @override
  Future<List<String>> getAuthors() {
    return _hymnService.getAuthors();
  }

  @override
  Future<void> initialize() {
    return _hymnService.initialize();
  }

  @override
  Future<void> refresh() {
    return _hymnService.refresh();
  }

  @override
  void clearCache() {
    _hymnService.clearCache();
  }

  @override
  Future<Map<String, dynamic>> exportData() {
    return _hymnService.exportData();
  }

  @override
  Future<void> importData(Map<String, dynamic> data) {
    return _hymnService.importData(data);
  }
}
