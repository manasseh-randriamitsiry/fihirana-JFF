import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/hymn/domain/repositories/hymn_repository.dart';

class GetFavoriteHymnsUseCase {
  final IHymnService _repository;

  GetFavoriteHymnsUseCase(this._repository);

  Future<List<Hymn>> call() {
    return _repository.getFavoriteHymns();
  }
}
