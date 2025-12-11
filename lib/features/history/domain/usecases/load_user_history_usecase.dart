import 'package:fihirana/features/history/domain/repositories/history_repository.dart';
import 'package:fihirana/features/history/domain/entities/history_item.dart';

/// Use case for loading user history
class LoadUserHistoryUseCase {
  final HistoryRepository _repository;

  LoadUserHistoryUseCase(this._repository);

  /// Execute the use case
  Future<List<HistoryItem>> call() async {
    return await _repository.loadUserHistory();
  }
}