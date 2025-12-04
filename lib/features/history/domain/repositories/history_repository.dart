import 'package:fihirana/features/history/domain/entities/history_item.dart';

/// Repository interface for history operations
abstract class HistoryRepository {
  /// Load user history
  Future<List<HistoryItem>> loadUserHistory();

  /// Add item to history
  Future<void> addToHistory(String hymnId, String title, String number);

  /// Delete selected history items
  Future<void> deleteHistoryItems(List<String> itemIds);

  /// Clear all history
  Future<void> clearHistory();

  /// Stream user history changes
  Stream<List<HistoryItem>> streamUserHistory();
}