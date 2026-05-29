import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:fihirana/features/bible/domain/entities/bible_highlight.dart';

/// Stores Bible highlights locally using Hive, for use when the user is not
/// authenticated (guest / offline mode).
class LocalBibleHighlightStorage {
  static const String _boxName = 'local_bible_highlights';

  static LocalBibleHighlightStorage? _instance;
  static LocalBibleHighlightStorage get instance {
    _instance ??= LocalBibleHighlightStorage._();
    return _instance!;
  }

  LocalBibleHighlightStorage._();

  Box<String>? _box;
  final _uuid = const Uuid();

  // Stream controllers keyed by "bookName_chapter" so individual pages
  // receive live updates when highlights change.
  final Map<String, StreamController<List<BibleHighlight>>> _streamControllers =
      {};

  /// Open the Hive box. Safe to call multiple times.
  Future<void> initialize() async {
    if (_box != null && _box!.isOpen) return;
    _box = await Hive.openBox<String>(_boxName);
  }

  Box<String> get _openBox {
    if (_box == null || !_box!.isOpen) {
      throw StateError('LocalBibleHighlightStorage is not initialized. '
          'Call initialize() first.');
    }
    return _box!;
  }

  // ── Storage helpers ────────────────────────────────────────────────────────

  String _highlightKey(String bookName, int chapter, String id) =>
      'hl_${bookName}_${chapter}_$id';

  String _chapterPrefix(String bookName, int chapter) =>
      'hl_${bookName}_${chapter}_';

  List<BibleHighlight> _highlightsForChapter(String bookName, int chapter) {
    final prefix = _chapterPrefix(bookName, chapter);
    final box = _openBox;
    final results = <BibleHighlight>[];

    for (final key in box.keys) {
      if (key is String && key.startsWith(prefix)) {
        try {
          final json =
              jsonDecode(box.get(key)!) as Map<String, dynamic>;
          results.add(BibleHighlight.fromJson(json));
        } catch (_) {}
      }
    }
    return results;
  }

  void _notifyChapterListeners(String bookName, int chapter) {
    final key = '${bookName}_$chapter';
    final controller = _streamControllers[key];
    if (controller != null && !controller.isClosed) {
      controller.add(_highlightsForChapter(bookName, chapter));
    }
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Live stream of highlights for one chapter (local only).
  Stream<List<BibleHighlight>> getHighlightsStream(
      String bookName, int chapter) {
    final key = '${bookName}_$chapter';
    if (!_streamControllers.containsKey(key) ||
        _streamControllers[key]!.isClosed) {
      _streamControllers[key] =
          StreamController<List<BibleHighlight>>.broadcast();
    }

    final controller = _streamControllers[key]!;

    // Emit the current state immediately.
    Future.microtask(
        () => controller.add(_highlightsForChapter(bookName, chapter)));

    return controller.stream;
  }

  /// Save a new local highlight. Returns the assigned id on success.
  Future<String?> saveHighlight(BibleHighlight highlight) async {
    try {
      final id = _uuid.v4();
      final withId = highlight.copyWith(
        id: id,
        userId: 'local',
        userName: 'local',
      );
      final key = _highlightKey(highlight.bookName, highlight.chapter, id);
      await _openBox.put(key, jsonEncode(withId.toJson()));
      _notifyChapterListeners(highlight.bookName, highlight.chapter);
      if (kDebugMode) print('✅ Local highlight saved: $id');
      return id;
    } catch (e) {
      if (kDebugMode) print('❌ Error saving local highlight: $e');
      return null;
    }
  }

  /// Delete a local highlight by id. Returns true on success.
  Future<bool> deleteHighlight(
      String highlightId, String bookName, int chapter) async {
    try {
      final key = _highlightKey(bookName, chapter, highlightId);
      if (!_openBox.containsKey(key)) return false;
      await _openBox.delete(key);
      _notifyChapterListeners(bookName, chapter);
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error deleting local highlight: $e');
      return false;
    }
  }

  /// Update an existing local highlight's color. Returns true on success.
  Future<bool> updateHighlight(BibleHighlight highlight) async {
    try {
      final key =
          _highlightKey(highlight.bookName, highlight.chapter, highlight.id);
      if (!_openBox.containsKey(key)) return false;
      await _openBox.put(key, jsonEncode(highlight.toJson()));
      _notifyChapterListeners(highlight.bookName, highlight.chapter);
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error updating local highlight: $e');
      return false;
    }
  }

  /// All local highlights (for a "My Highlights" list).
  List<BibleHighlight> getAllHighlights() {
    final box = _openBox;
    final results = <BibleHighlight>[];
    for (final key in box.keys) {
      if (key is String && key.startsWith('hl_')) {
        try {
          final json =
              jsonDecode(box.get(key)!) as Map<String, dynamic>;
          results.add(BibleHighlight.fromJson(json));
        } catch (_) {}
      }
    }
    results.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return results;
  }

  bool isLocalHighlight(BibleHighlight h) => h.userId == 'local';

  void dispose() {
    for (final c in _streamControllers.values) {
      c.close();
    }
    _streamControllers.clear();
  }
}
