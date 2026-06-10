import 'package:fihirana/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/favorites/domain/entities/favorite.dart';
import 'package:fihirana/features/hymn/data/services/hymn_service.dart';
import 'package:fihirana/features/audio/data/services/audio_service.dart';

/// Implementation of FavoritesRepository
class FavoritesRepositoryImpl implements FavoritesRepository {
  final HymnService _hymnService;
  final AudioService _audioService;

  FavoritesRepositoryImpl(this._hymnService, this._audioService);

  @override
  Stream<List<Hymn>> getFavoriteHymnsStream() {
    return _hymnService.getFavoriteHymnsStream();
  }

  @override
  Future<void> toggleFavorite(Hymn hymn) async {
    return await _hymnService.toggleFavorite(hymn);
  }

  @override
  Future<bool> checkAudioAvailability(String hymnId) async {
    return await _audioService.checkAudioFileExists(hymnId);
  }

  @override
  bool isHymnPlaying(String hymnId) {
    return _audioService.isHymnPlaying(hymnId);
  }

  @override
  Future<List<Favorite>> getAllFavorites() async {
    // This would need to be implemented in hymn service if needed
    // For now, return empty list as it's not used in the controller
    return [];
  }

  @override
  Stream<List<Favorite>> streamAllFavorites() {
    // This would need to be implemented in hymn service if needed
    // For now, return empty stream as it's not used in the controller
    return Stream.value([]);
  }
}
