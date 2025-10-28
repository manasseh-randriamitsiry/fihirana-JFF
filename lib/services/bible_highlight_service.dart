import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/bible_highlight.dart';
import '../controller/auth_controller.dart';

class BibleHighlightService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthController _authController = Get.find<AuthController>();

  // Get highlights for a specific book and chapter for the current user
  Stream<List<BibleHighlight>> getHighlightsStream(String bookName, int chapter) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

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

  // Get all highlights for a specific book and chapter (public highlights)
  Stream<List<BibleHighlight>> getPublicHighlightsStream(String bookName, int chapter) {
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

  // Save a new highlight
  Future<bool> saveHighlight(BibleHighlight highlight) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final highlightData = highlight.toJson();
      await _firestore.collection('bible_highlights').add(highlightData);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving highlight: $e');
      }
      return false;
    }
  }

  // Update an existing highlight
  Future<bool> updateHighlight(BibleHighlight highlight) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Check if user owns the highlight or is admin
      if (!_authController.isAdmin && highlight.userId != user.uid) {
        return false;
      }

      await _firestore.collection('bible_highlights').doc(highlight.id).update({
        'startVerse': highlight.startVerse,
        'endVerse': highlight.endVerse,
        'color': highlight.color,
        'updatedAt': highlight.updatedAt.toIso8601String(),
      });

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating highlight: $e');
      }
      return false;
    }
  }

  // Delete a highlight
  Future<bool> deleteHighlight(String highlightId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Get the highlight to check ownership
      final highlightDoc = await _firestore.collection('bible_highlights').doc(highlightId).get();
      if (!highlightDoc.exists) return false;

      final data = highlightDoc.data();
      if (data == null) return false;
      
      data['id'] = highlightDoc.id;
      final highlight = BibleHighlight.fromJson(data);

      // Check if user is admin or owns the highlight
      if (!_authController.isAdmin && highlight.userId != user.uid) {
        return false; // Not authorized
      }

      await _firestore.collection('bible_highlights').doc(highlightId).delete();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting highlight: $e');
      }
      return false;
    }
  }

  // Check if current user can edit a highlight (owns it or is admin)
  Future<bool> canEditHighlight(BibleHighlight highlight) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Admins can edit all highlights
    if (_authController.isAdmin) {
      return true;
    }

    // Users can edit their own highlights
    return highlight.userId == user.uid;
  }
}