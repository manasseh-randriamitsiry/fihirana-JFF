import 'package:fihirana/features/bible/domain/repositories/bible_repository.dart';

class GetRandomVerseUseCase {
  final IBibleService _repository;

  GetRandomVerseUseCase(this._repository);

  VerseSearchResult? call() {
    return _repository.getRandomVerse();
  }
}