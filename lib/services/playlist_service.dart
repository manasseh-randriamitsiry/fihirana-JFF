import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/playlist.dart';

class PlaylistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new playlist
  Future<String?> createPlaylist(String title, DateTime date,
      {bool isPublic = false}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final now = DateTime.now();
      final playlistData = {
        'title': title,
        'date': Timestamp.fromDate(date),
        'hymnIds': [],
        'createdBy': user.uid,
        'isPublic': isPublic,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      final docRef = await _firestore.collection('playlists').add(playlistData);
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating playlist: $e');
      }
      return null;
    }
  }

  // Get playlists for the current user
  Stream<List<Playlist>> getUserPlaylistsStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('playlists')
        .where('createdBy', isEqualTo: user.uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Playlist.fromJson(data);
      }).toList();
    });
  }

  // Get a specific playlist by ID
  Future<Playlist?> getPlaylistById(String id) async {
    try {
      final doc = await _firestore.collection('playlists').doc(id).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return Playlist.fromJson(data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting playlist: $e');
      }
      return null;
    }
  }

  // Add a hymn to a playlist
  Future<bool> addHymnToPlaylist(String playlistId, String hymnId) async {
    try {
      await _firestore.collection('playlists').doc(playlistId).update({
        'hymnIds': FieldValue.arrayUnion([hymnId]),
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding hymn to playlist: $e');
      }
      return false;
    }
  }

  // Remove a hymn from a playlist
  Future<bool> removeHymnFromPlaylist(String playlistId, String hymnId) async {
    try {
      await _firestore.collection('playlists').doc(playlistId).update({
        'hymnIds': FieldValue.arrayRemove([hymnId]),
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error removing hymn from playlist: $e');
      }
      return false;
    }
  }

  // Delete a playlist
  Future<bool> deletePlaylist(String playlistId) async {
    try {
      await _firestore.collection('playlists').doc(playlistId).delete();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting playlist: $e');
      }
      return false;
    }
  }

  // Update playlist details
  Future<bool> updatePlaylist(String playlistId,
      {String? title, DateTime? date, bool? isPublic}) async {
    try {
      final Map<String, dynamic> updates = {
        'updatedAt': Timestamp.now(),
      };

      if (title != null) updates['title'] = title;
      if (date != null) updates['date'] = Timestamp.fromDate(date);
      if (isPublic != null) updates['isPublic'] = isPublic;

      await _firestore.collection('playlists').doc(playlistId).update(updates);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating playlist: $e');
      }
      return false;
    }
  }
}
