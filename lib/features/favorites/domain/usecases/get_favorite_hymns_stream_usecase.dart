import 'package:fihirana/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';

/// Use case for getting favorite hymns stream
class GetFavoriteHymnsStreamUseCase {
  final FavoritesRepository _repository;

  GetFavoriteHymnsStreamUseCase(this._repository);

  /// Execute the use case
  Stream<List<Hymn>> call() {
    return _repository.getFavoriteHymnsStream();
  }
}
