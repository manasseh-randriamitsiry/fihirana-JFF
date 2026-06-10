import 'package:fihirana/features/daily_verse/domain/repositories/daily_verse_repository.dart';

/// Use case for sending test notification
class SendTestNotificationUseCase {
  final DailyVerseRepository _repository;

  SendTestNotificationUseCase(this._repository);

  /// Execute the use case
  Future<void> call() async {
    return await _repository.sendTestNotification();
  }
}
