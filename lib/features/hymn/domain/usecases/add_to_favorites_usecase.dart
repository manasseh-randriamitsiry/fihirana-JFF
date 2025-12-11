import 'package:fihirana/features/hymn/domain/repositories/hymn_repository.dart';

class AddToFavoritesUseCase {
  final IHymnService _repository;

  AddToFavoritesUseCase(this._repository);

  Future<void> call(String hymnId) {
    return _repository.addToFavorites(hymnId);
  }
}