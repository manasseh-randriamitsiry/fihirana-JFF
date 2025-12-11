import 'package:fihirana/features/bible/domain/repositories/bible_repository.dart';
import 'package:fihirana/features/bible/domain/entities/bible.dart';

class GetChapterUseCase {
  final IBibleService _repository;

  GetChapterUseCase(this._repository);

  BibleChapter? call(String bookName, int chapterNumber) {
    return _repository.getChapter(bookName, chapterNumber);
  }
}