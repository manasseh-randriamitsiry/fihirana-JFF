import 'package:fihirana/features/history/domain/repositories/history_repository.dart';

/// Use case for deleting selected history items
class DeleteSelectedHistoryItemsUseCase {
  final HistoryRepository _repository;

  DeleteSelectedHistoryItemsUseCase(this._repository);

  /// Execute the use case
  Future<void> call(List<String> itemIds) async {
    return await _repository.deleteHistoryItems(itemIds);
  }
}