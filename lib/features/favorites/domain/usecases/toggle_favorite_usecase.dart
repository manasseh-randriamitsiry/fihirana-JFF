import 'package:fihirana/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';

/// Use case for toggling favorite status
class ToggleFavoriteUseCase {
  final FavoritesRepository _repository;

  ToggleFavoriteUseCase(this._repository);

  /// Execute the use case
  Future<void> call(Hymn hymn) async {
    return await _repository.toggleFavorite(hymn);
  }
}
