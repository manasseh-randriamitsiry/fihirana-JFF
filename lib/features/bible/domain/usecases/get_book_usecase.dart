import 'package:fihirana/features/bible/domain/repositories/bible_repository.dart';
import 'package:fihirana/features/bible/domain/entities/bible.dart';

class GetBookUseCase {
  final IBibleService _repository;

  GetBookUseCase(this._repository);

  BibleBook? call(String bookName) {
    return _repository.getBook(bookName);
  }
}
