import 'package:fihirana/features/hymn/domain/repositories/hymn_repository.dart';

class RemoveFromFavoritesUseCase {
  final IHymnService _repository;

  RemoveFromFavoritesUseCase(this._repository);

  Future<void> call(String hymnId) {
    return _repository.removeFromFavorites(hymnId);
  }
}
