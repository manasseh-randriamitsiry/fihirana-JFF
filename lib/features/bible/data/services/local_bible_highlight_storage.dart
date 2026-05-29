import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:fihirana/features/bible/domain/entities/bible_highlight.dart';

/// Stores Bible highlights locally using Hive, for use when the user is not
/// authenticated (guest / offline mode).
///
/// The class is **self-initializing** – every public method calls [_ensureReady]
/// which opens the Hive box on first use (idempotent).  Callers do NOT need to
/// call [initialize] explicitly, though doing so eagerly (e.g. in
/// LoadingScreen) is fine and will make the first access instant.
class LocalBibleHighlightStorage {
  static const String _boxName = 'local_bible_highlights';

  static LocalBibleHighlightStorage? _instance;
  static LocalBibleHighlightStorage get instance {
    _instance ??= LocalBibleHighlightStorage._();
    return _instance!;
  }

  LocalBibleHighlightStorage._();

  Box<String>? _box;
  Future<Box<String>>? _openFuture; // single in-flight open operation
  final _uuid = const Uuid();

  // Stream controllers keyed by "bookName_chapter".
  final Map<String, StreamController<List<BibleHighlight>>> _streamControllers =
      {};

  // ── Initialization ─────────────────────────────────────────────────────────

  /// Eagerly open the Hive box.  Safe to call multiple times.
  Future<void> initialize() async {
    await _ensureReady();
  }

  /// Returns the open box, initializing it if necessary.
  Future<Box<String>> _ensureReady() async {
    if (_box != null && _box!.isOpen) return _box!;

    // Deduplicate concurrent calls – only one openBox call is in flight.
    _openFuture ??= _openBox();
    _box = await _openFuture!;
    _openFuture = null;
    return _box!;
  }

  Future<Box<String>> _openBox() async {
    // Hive.initFlutter() is safe to call multiple times (no-op if already
    // initialized).  This makes the storage robust even if LoadingScreen
    // hasn't finished yet.
    await Hive.initFlutter();
    return Hive.openBox<String>(_boxName);
  }

  // ── Storage helpers ────────────────────────────────────────────────────────

  String _highlightKey(String bookName, int chapter, String id) =>
      'hl_${bookName}_${chapter}_$id';

  String _chapterPrefix(String bookName, int chapter) =>
      'hl_${bookName}_${chapter}_';

  Future<List<BibleHighlight>> _highlightsForChapter(
      String bookName, int chapter) async {
    final box = await _ensureReady();
    final prefix = _chapterPrefix(bookName, chapter);
    final results = <BibleHighlight>[];

    for (final key in box.keys) {
      if (key is String && key.startsWith(prefix)) {
        try {
          final json = jsonDecode(box.get(key)!) as Map<String, dynamic>;
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
      _highlightsForChapter(bookName, chapter).then((list) {
        if (!controller.isClosed) controller.add(list);
      });
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

    // Emit current state asynchronously (after init if needed).
    _highlightsForChapter(bookName, chapter).then((list) {
      if (!controller.isClosed) controller.add(list);
    });

    return controller.stream;
  }

  /// Save a new local highlight.  Returns the assigned id on success.
  Future<String?> saveHighlight(BibleHighlight highlight) async {
    try {
      final box = await _ensureReady();
      final id = _uuid.v4();
      final withId = highlight.copyWith(
        id: id,
        userId: 'local',
        userName: 'local',
      );
      final key = _highlightKey(highlight.bookName, highlight.chapter, id);
      await box.put(key, jsonEncode(withId.toJson()));
      _notifyChapterListeners(highlight.bookName, highlight.chapter);
      if (kDebugMode) print('✅ Local highlight saved: $id');
      return id;
    } catch (e) {
      if (kDebugMode) print('❌ Error saving local highlight: $e');
      return null;
    }
  }

  /// Delete a local highlight by id.  Returns true on success.
  Future<bool> deleteHighlight(
      String highlightId, String bookName, int chapter) async {
    try {
      final box = await _ensureReady();
      final key = _highlightKey(bookName, chapter, highlightId);
      if (!box.containsKey(key)) return false;
      await box.delete(key);
      _notifyChapterListeners(bookName, chapter);
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error deleting local highlight: $e');
      return false;
    }
  }

  /// Update an existing local highlight's color.  Returns true on success.
  Future<bool> updateHighlight(BibleHighlight highlight) async {
    try {
      final box = await _ensureReady();
      final key =
          _highlightKey(highlight.bookName, highlight.chapter, highlight.id);
      if (!box.containsKey(key)) return false;
      await box.put(key, jsonEncode(highlight.toJson()));
      _notifyChapterListeners(highlight.bookName, highlight.chapter);
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error updating local highlight: $e');
      return false;
    }
  }

  /// All local highlights (for a "My Highlights" list).
  Future<List<BibleHighlight>> getAllHighlights() async {
    final box = await _ensureReady();
    final results = <BibleHighlight>[];
    for (final key in box.keys) {
      if (key is String && key.startsWith('hl_')) {
        try {
          final json = jsonDecode(box.get(key)!) as Map<String, dynamic>;
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
