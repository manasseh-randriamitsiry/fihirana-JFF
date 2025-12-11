import 'package:fihirana/features/history/domain/repositories/history_repository.dart';
import 'package:fihirana/features/history/domain/entities/history_item.dart';
import 'package:fihirana/core/utils/firebase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

/// Implementation of HistoryRepository
class HistoryRepositoryImpl implements HistoryRepository {
  final FirebaseSyncService _firebaseSyncService;
  final SharedPreferences _prefs;
  final FirebaseAuth _auth;

  static const String _localHistoryKey = 'local_hymn_history';

  HistoryRepositoryImpl(this._firebaseSyncService, this._prefs, this._auth);

  @override
  Future<List<HistoryItem>> loadUserHistory() async {
    final user = _auth.currentUser;

    if (user != null) {
      final firebaseHistory = await _firebaseSyncService.loadHistoryFromFirebase();
      return firebaseHistory.map((item) => HistoryItem.fromMap(item)).toList();
    } else {
      final localHistory = _prefs.getString(_localHistoryKey);
      if (localHistory != null) {
        final List<dynamic> decoded = json.decode(localHistory);
        return decoded.map((item) => HistoryItem.fromMap(Map<String, dynamic>.from(item))).toList();
      }
      return [];
    }
  }

  @override
  Future<void> addToHistory(String hymnId, String title, String number) async {
    final user = _auth.currentUser;

    if (kDebugMode) {
      print('HistoryRepositoryImpl: User authenticated: ${user != null}');
    }

    if (user != null) {
      if (kDebugMode) {
        print('HistoryRepositoryImpl: Saving to Firebase');
      }
      await _firebaseSyncService.addHistoryToFirebase(hymnId, title, number);
    } else {
      if (kDebugMode) {
        print('HistoryRepositoryImpl: Saving locally');
      }
      List<Map<String, dynamic>> localHistory = [];

      final existingHistory = _prefs.getString(_localHistoryKey);
      if (existingHistory != null) {
        final List<dynamic> decoded = json.decode(existingHistory);
        localHistory = decoded.cast<Map<String, dynamic>>().toList();
      }

      final historyEntry = HistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        hymnId: hymnId,
        title: title,
        number: number,
        timestamp: DateTime.now(),
      ).toMap();

      localHistory.insert(0, historyEntry);

      if (localHistory.length > 100) {
        localHistory = localHistory.sublist(0, 100);
      }

      await _prefs.setString(_localHistoryKey, json.encode(localHistory));
      if (kDebugMode) {
        print('HistoryRepositoryImpl: Saved locally, total items: ${localHistory.length}');
      }
    }
  }

  @override
  Future<void> deleteHistoryItems(List<String> itemIds) async {
    final user = _auth.currentUser;

    if (user != null) {
      // Assuming FirebaseSyncService has a method to delete multiple items
      // If not, we need to implement it or use batch delete directly
      // For now, using the existing batch delete logic from controller
      // This might need to be moved to FirebaseSyncService
      throw UnimplementedError('Delete multiple items from Firebase not implemented');
    } else {
      List<Map<String, dynamic>> localHistory = [];
      String? historyJson = _prefs.getString(_localHistoryKey);
      if (historyJson != null) {
        localHistory = List<Map<String, dynamic>>.from(
            jsonDecode(historyJson).map((x) => Map<String, dynamic>.from(x)));
        localHistory.removeWhere((item) => itemIds.contains(item['id']));
        await _prefs.setString(_localHistoryKey, jsonEncode(localHistory));
      }
    }
  }

  @override
  Future<void> clearHistory() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firebaseSyncService.clearHistoryFromFirebase();
    } else {
      await _prefs.remove(_localHistoryKey);
    }
  }

  @override
  Stream<List<HistoryItem>> streamUserHistory() {
    // This would require implementing a stream in FirebaseSyncService
    // For now, return empty stream
    return Stream.value([]);
  }
}