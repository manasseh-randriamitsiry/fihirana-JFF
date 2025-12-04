import 'package:fihirana/features/bible/domain/repositories/bible_repository.dart';
import 'package:fihirana/features/bible/domain/entities/bible.dart';

class GetAllBooksUseCase {
  final IBibleService _repository;

  GetAllBooksUseCase(this._repository);

  List<BibleBook> call() {
    return _repository.getAllBooks();
  }
}