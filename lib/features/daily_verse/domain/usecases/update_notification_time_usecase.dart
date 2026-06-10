import 'package:fihirana/features/daily_verse/domain/repositories/daily_verse_repository.dart';

/// Use case for updating notification time
class UpdateNotificationTimeUseCase {
  final DailyVerseRepository _repository;

  UpdateNotificationTimeUseCase(this._repository);

  /// Execute the use case
  Future<void> call(int hour, int minute, bool isEnabled) async {
    if (isEnabled) {
      await _repository.scheduleDailyNotification(hour, minute);
    }
  }
}
