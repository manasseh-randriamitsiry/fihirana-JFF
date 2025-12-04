import 'package:fihirana/features/bible/domain/repositories/bible_repository.dart';
import 'package:fihirana/features/bible/domain/entities/bible.dart';

class SearchBooksUseCase {
  final IBibleService _repository;

  SearchBooksUseCase(this._repository);

  List<BibleBook> call(String query) {
    return _repository.searchBooks(query);
  }
}