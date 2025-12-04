import 'package:fihirana/features/daily_verse/domain/repositories/daily_verse_repository.dart';

/// Use case for loading daily verse settings
class LoadDailyVerseSettingsUseCase {
  final DailyVerseRepository _repository;

  LoadDailyVerseSettingsUseCase(this._repository);

  /// Execute the use case
  Future<Map<String, dynamic>> call() async {
    return await _repository.loadSettings();
  }
}