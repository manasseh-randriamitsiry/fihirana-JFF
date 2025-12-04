import 'package:fihirana/features/history/domain/repositories/history_repository.dart';

/// Use case for clearing history
class ClearHistoryUseCase {
  final HistoryRepository _repository;

  ClearHistoryUseCase(this._repository);

  /// Execute the use case
  Future<void> call() async {
    return await _repository.clearHistory();
  }
}