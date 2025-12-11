import 'package:fihirana/features/daily_verse/domain/repositories/daily_verse_repository.dart';

/// Use case for toggling daily verse feature
class ToggleDailyVerseUseCase {
  final DailyVerseRepository _repository;

  ToggleDailyVerseUseCase(this._repository);

  /// Execute the use case
  Future<void> call(bool enabled, int hour, int minute) async {
    if (enabled) {
      await _repository.scheduleDailyNotification(hour, minute);
    } else {
      await _repository.cancelDailyNotifications();
    }
  }
}