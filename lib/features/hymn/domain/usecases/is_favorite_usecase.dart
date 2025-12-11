import 'package:fihirana/features/hymn/domain/repositories/hymn_repository.dart';

class IsFavoriteUseCase {
  final IHymnService _repository;

  IsFavoriteUseCase(this._repository);

  Future<bool> call(String hymnId) {
    return _repository.isFavorite(hymnId);
  }
}