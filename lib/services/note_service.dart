import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/note.dart';
import '../controller/auth_controller.dart';

class NoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthController _authController = Get.find<AuthController>();

  // Get notes for a specific hymn and user
  Future<Note?> getNote(String hymnId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final snapshot = await _firestore
          .collection('notes')
          .where('hymnId', isEqualTo: hymnId)
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        // Ensure all required fields are present
        data['id'] = doc.id;
        return Note.fromJson(data);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting note: $e');
      }
      return null;
    }
  }

  // Get all public notes for a hymn (visible to all users)
  Stream<List<Note>> getPublicNotesStream(String hymnId) {
    return _firestore
        .collection('notes')
        .where('hymnId', isEqualTo: hymnId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Note.fromJson(data);
      }).toList();
    });
  }

  // Save or update a note
  Future<bool> saveNote(String hymnId, String content) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final existingNote = await getNote(hymnId);
      final now = DateTime.now();

      // Get user's display name
      final displayName = user.displayName ?? user.email ?? 'Anonymous';

      if (existingNote != null) {
        // Update existing note
        await _firestore.collection('notes').doc(existingNote.id).update({
          'content': content,
          'updatedAt': now.toIso8601String(),
        });
      } else {
        // Create new note
        final noteData = {
          'hymnId': hymnId,
          'userId': user.uid,
          'content': content,
          'userName': displayName,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        };

        await _firestore.collection('notes').add(noteData);
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving note: $e');
      }
      return false;
    }
  }

  // Check if current user can edit a note (owns it or is admin)
  Future<bool> canEditNote(Note note) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Admins can edit all notes
    if (_authController.isAdmin) {
      return true;
    }

    // Users can edit their own notes
    return note.userId == user.uid;
  }

  // Delete a note (only owner or admin can delete)
  Future<bool> deleteNote(String noteId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Get the note to check ownership
      final noteDoc = await _firestore.collection('notes').doc(noteId).get();
      if (!noteDoc.exists) return false;

      final data = noteDoc.data();
      if (data == null) return false;
      
      data['id'] = noteDoc.id;
      final note = Note.fromJson(data);

      // Check if user is admin or owns the note
      if (!_authController.isAdmin && note.userId != user.uid) {
        return false; // Not authorized
      }

      await _firestore.collection('notes').doc(noteId).delete();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting note: $e');
      }
      return false;
    }
  }
}