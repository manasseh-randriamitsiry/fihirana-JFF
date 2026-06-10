import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/hymn/domain/repositories/hymn_repository.dart';

class SearchHymnsUseCase {
  final IHymnService _repository;

  SearchHymnsUseCase(this._repository);

  Future<List<Hymn>> call(String query) {
    return _repository.searchHymns(query);
  }
}
