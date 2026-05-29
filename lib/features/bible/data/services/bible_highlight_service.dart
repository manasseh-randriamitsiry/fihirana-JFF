import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/bible/domain/entities/bible_highlight.dart';
import 'package:fihirana/features/auth/presentation/controllers/auth_controller.dart';
import 'package:fihirana/features/bible/domain/repositories/i_bible_highlight_service.dart';
import 'package:fihirana/features/bible/data/services/local_bible_highlight_storage.dart';

/// Hybrid highlight service.
///
/// * Authenticated users  → Firestore (synced across devices).
/// * Unauthenticated users → [LocalBibleHighlightStorage] (Hive, device-only).
///
/// This means guest users can highlight verses freely; their highlights are
/// preserved locally until they sign in.  No Crashlytics errors are thrown
/// for unauthenticated highlight attempts.
class BibleHighlightService implements IBibleHighlightService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthController _authController = Get.find<AuthController>();
  final LocalBibleHighlightStorage _local = LocalBibleHighlightStorage.instance;

  bool get _isAuthenticated => _auth.currentUser != null;

  // ── Streams ────────────────────────────────────────────────────────────────

  @override
  Stream<List<BibleHighlight>> getHighlightsStream(
      String bookName, int chapter) {
    if (!_isAuthenticated) {
      return _local.getHighlightsStream(bookName, chapter);
    }
    final user = _auth.currentUser!;
    return _firestore
        .collection('bible_highlights')
        .where('bookName', isEqualTo: bookName)
        .where('chapter', isEqualTo: chapter)
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return BibleHighlight.fromJson(data);
      }).toList();
    });
  }

  @override
  Stream<List<BibleHighlight>> getPublicHighlightsStream(
      String bookName, int chapter) {
    if (!_isAuthenticated) {
      // No public highlights for guest mode — return empty stream.
      return Stream.value([]);
    }
    return _firestore
        .collection('bible_highlights')
        .where('bookName', isEqualTo: bookName)
        .where('chapter', isEqualTo: chapter)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return BibleHighlight.fromJson(data);
      }).toList();
    });
  }

  @override
  Stream<List<BibleHighlight>> getAllUserHighlightsStream() {
    if (!_isAuthenticated) {
      return Stream.fromFuture(_local.getAllHighlights());
    }
    final user = _auth.currentUser!;
    return _firestore
        .collection('bible_highlights')
        .where('userId', isEqualTo: user.uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return BibleHighlight.fromJson(data);
      }).toList();
    });
  }

  // ── Write operations ───────────────────────────────────────────────────────

  @override
  Future<bool> saveHighlight(BibleHighlight highlight) async {
    if (!_isAuthenticated) {
      // Guest mode: persist locally — no error, no crash report.
      final id = await _local.saveHighlight(highlight);
      return id != null;
    }

    try {
      final user = _auth.currentUser!;
      final highlightData = highlight.toJson();
      highlightData['userId'] = user.uid;
      highlightData['userName'] =
          user.displayName ?? user.email ?? 'Unknown';
      highlightData['createdAt'] = DateTime.now().toIso8601String();
      highlightData['updatedAt'] = DateTime.now().toIso8601String();

      await _firestore.collection('bible_highlights').add(highlightData);

      if (kDebugMode) print('✅ Highlight saved to Firestore');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error saving highlight to Firestore: $e');
      return false;
    }
  }

  @override
  Future<bool> updateHighlight(BibleHighlight highlight) async {
    if (!_isAuthenticated) {
      if (!_local.isLocalHighlight(highlight)) return false;
      return _local.updateHighlight(highlight);
    }

    try {
      final user = _auth.currentUser!;
      if (!_authController.isAdmin && highlight.userId != user.uid) {
        return false;
      }
      await _firestore
          .collection('bible_highlights')
          .doc(highlight.id)
          .update({
        'startVerse': highlight.startVerse,
        'endVerse': highlight.endVerse,
        'color': highlight.color,
        'updatedAt': highlight.updatedAt.toIso8601String(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) print('Error updating highlight: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteHighlight(String highlightId) async {
    if (!_isAuthenticated) {
      // For local highlights we need bookName + chapter; search all.
      final all = await _local.getAllHighlights();
      final match = all.where((h) => h.id == highlightId).firstOrNull;
      if (match == null) return false;
      return _local.deleteHighlight(highlightId, match.bookName, match.chapter);
    }

    try {
      final user = _auth.currentUser!;
      final doc = await _firestore
          .collection('bible_highlights')
          .doc(highlightId)
          .get();
      if (!doc.exists) return false;

      final data = doc.data();
      if (data == null) return false;
      data['id'] = doc.id;
      final highlight = BibleHighlight.fromJson(data);

      if (!_authController.isAdmin && highlight.userId != user.uid) {
        return false;
      }

      await _firestore
          .collection('bible_highlights')
          .doc(highlightId)
          .delete();
      return true;
    } catch (e) {
      if (kDebugMode) print('Error deleting highlight: $e');
      return false;
    }
  }

  @override
  Future<bool> canEditHighlight(BibleHighlight highlight) async {
    if (!_isAuthenticated) {
      return _local.isLocalHighlight(highlight);
    }
    final user = _auth.currentUser!;
    if (_authController.isAdmin) return true;
    return highlight.userId == user.uid;
  }
}