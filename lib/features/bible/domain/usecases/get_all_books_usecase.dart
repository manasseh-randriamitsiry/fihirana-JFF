import 'package:fihirana/features/bible/domain/repositories/bible_repository.dart';
import 'package:fihirana/features/bible/domain/entities/bible.dart';

class GetAllBooksUseCase {
  final IBibleService _repository;

  GetAllBooksUseCase(this._repository);

  List<BibleBook> call() {
    return _repository.getAllBooks();
  }

  Map<String, List<String>> getAllBooksByTestament() {
    return _repository.getAllBooksByTestament();
  }

  List<String> getOldTestamentBooks() {
    return _repository.getOldTestamentBooks();
  }

  List<String> getNewTestamentBooks() {
    return _repository.getNewTestamentBooks();
  }

  Map<String, dynamic> getLoadedBooksInfo() {
    return _repository.getLoadedBooksInfo();
  }
}