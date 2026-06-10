import 'package:fihirana/features/history/domain/repositories/history_repository.dart';

/// Use case for adding to history
class AddToHistoryUseCase {
  final HistoryRepository _repository;

  AddToHistoryUseCase(this._repository);

  /// Execute the use case
  Future<void> call(String hymnId, String title, String number) async {
    return await _repository.addToHistory(hymnId, title, number);
  }
}
