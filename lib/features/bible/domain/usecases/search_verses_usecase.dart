import 'package:fihirana/features/bible/domain/repositories/bible_repository.dart';

class SearchVersesUseCase {
  final IBibleService _repository;

  SearchVersesUseCase(this._repository);

  List<VerseSearchResult> call(String query) {
    return _repository.searchVerses(query);
  }
}