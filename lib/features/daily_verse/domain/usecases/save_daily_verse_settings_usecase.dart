import 'package:fihirana/features/daily_verse/domain/repositories/daily_verse_repository.dart';

/// Use case for saving daily verse settings
class SaveDailyVerseSettingsUseCase {
  final DailyVerseRepository _repository;

  SaveDailyVerseSettingsUseCase(this._repository);

  /// Execute the use case
  Future<void> call(bool isEnabled, int hour, int minute) async {
    return await _repository.saveSettings(isEnabled, hour, minute);
  }
}