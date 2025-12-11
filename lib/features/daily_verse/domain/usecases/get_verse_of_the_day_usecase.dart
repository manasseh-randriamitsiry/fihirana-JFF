import 'package:fihirana/features/daily_verse/domain/repositories/daily_verse_repository.dart';
import 'package:fihirana/features/daily_verse/domain/entities/daily_verse.dart';

/// Use case for getting the verse of the day
class GetVerseOfTheDayUseCase {
  final DailyVerseRepository _repository;

  GetVerseOfTheDayUseCase(this._repository);

  /// Execute the use case
  Future<DailyVerse> call() async {
    return await _repository.getVerseOfTheDay();
  }
}