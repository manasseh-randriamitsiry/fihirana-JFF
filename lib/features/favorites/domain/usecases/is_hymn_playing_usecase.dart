import 'package:fihirana/features/favorites/domain/repositories/favorites_repository.dart';

/// Use case for checking if hymn is playing
class IsHymnPlayingUseCase {
  final FavoritesRepository _repository;

  IsHymnPlayingUseCase(this._repository);

  /// Execute the use case
  bool call(String hymnId) {
    return _repository.isHymnPlaying(hymnId);
  }
}