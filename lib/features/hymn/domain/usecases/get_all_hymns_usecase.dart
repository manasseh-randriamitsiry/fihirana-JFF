import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/hymn/domain/repositories/hymn_repository.dart';

class GetAllHymnsUseCase {
  final IHymnService _repository;

  GetAllHymnsUseCase(this._repository);

  Future<List<Hymn>> call() {
    return _repository.getAllHymns();
  }
}
