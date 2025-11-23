import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist.dart';

class PlaylistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _localPlaylistsKey = 'local_playlists';
  static const String _playlistsSyncedKey = 'playlists_synced';

  // Generate a local ID for playlists
  String _generateLocalId() {
    return 'local_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Get local playlists from SharedPreferences
  Future<List<Playlist>> getLocalPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playlistsJson = prefs.getString(_localPlaylistsKey);
      if (playlistsJson == null) return [];

      final List<dynamic> decoded = json.decode(playlistsJson);
      return decoded.map((json) => Playlist.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading local playlists: $e');
      }
      return [];
    }
  }

  // Save local playlists to SharedPreferences
  Future<void> saveLocalPlaylists(List<Playlist> playlists) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = json.encode(playlists.map((p) => p.toJson()).toList());
      await prefs.setString(_localPlaylistsKey, encoded);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving local playlists: $e');
      }
    }
  }

  // Create a new playlist (works offline)
  Future<String?> createPlaylist(String title, DateTime date,
      {bool isPublic = false}) async {
    try {
      final user = _auth.currentUser;
      final now = DateTime.now();

      // Create locally first
      final localId = _generateLocalId();
      final playlist = Playlist(
        id: localId,
        title: title,
        date: date,
        hymnIds: [],
        createdBy: user?.uid ?? 'local',
        isPublic: isPublic,
        isLocal: user == null,
        createdAt: now,
        updatedAt: now,
      );

      final localPlaylists = await getLocalPlaylists();
      localPlaylists.add(playlist);
      await saveLocalPlaylists(localPlaylists);

      // Notify listeners
      notifyPlaylistsChanged();

      // Sync to Firebase if authenticated
      if (user != null) {
        try {
          final playlistData = playlist.toFirestore();
          final docRef =
              await _firestore.collection('playlists').add(playlistData);

          // Update local playlist with Firebase ID
          final updatedPlaylist = playlist.copyWith(
            id: docRef.id,
            isLocal: false,
          );
          final index = localPlaylists.indexWhere((p) => p.id == localId);
          if (index != -1) {
            localPlaylists[index] = updatedPlaylist;
            await saveLocalPlaylists(localPlaylists);
            notifyPlaylistsChanged();
          }

          return docRef.id;
        } catch (e) {
          if (kDebugMode) {
            print('Failed to sync to Firebase, keeping local: $e');
          }
        }
      }

      return localId;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating playlist: $e');
      }
      return null;
    }
  }

  // Stream controller for manual updates
  final _playlistsController = StreamController<List<Playlist>>.broadcast();

  // Get playlists for the current user (combines local + Firebase)
  Stream<List<Playlist>> getUserPlaylistsStream() {
    final user = _auth.currentUser;

    // Function to load and emit playlists
    Future<void> emitPlaylists() async {
      final localPlaylists = await getLocalPlaylists();

      if (user == null) {
        // No user, just return local playlists
        _playlistsController.add(localPlaylists);
      } else {
        // User authenticated, merge with Firebase
        try {
          final firebaseSnapshot = await _firestore
              .collection('playlists')
              .where('createdBy', isEqualTo: user.uid)
              .orderBy('date', descending: true)
              .get();

          final firebasePlaylists = firebaseSnapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            data['isLocal'] = false;
            return Playlist.fromJson(data);
          }).toList();

          // Merge: Firebase playlists + local-only playlists
          final firebaseIds = firebasePlaylists.map((p) => p.id).toSet();
          final uniqueLocal =
              localPlaylists.where((p) => !firebaseIds.contains(p.id)).toList();

          final combined = [...firebasePlaylists, ...uniqueLocal];
          combined.sort((a, b) => b.date.compareTo(a.date));

          _playlistsController.add(combined);
        } catch (e) {
          if (kDebugMode) {
            print('Error loading Firebase playlists, using local only: $e');
          }
          _playlistsController.add(localPlaylists);
        }
      }
    }

    // Emit initial playlists
    emitPlaylists();

    // Listen to Firebase changes if authenticated
    if (user != null) {
      _firestore
          .collection('playlists')
          .where('createdBy', isEqualTo: user.uid)
          .orderBy('date', descending: true)
          .snapshots()
          .listen((_) => emitPlaylists());
    }

    return _playlistsController.stream;
  }

  // Call this after any local playlist modification
  void notifyPlaylistsChanged() {
    // Re-emit playlists
    final user = _auth.currentUser;
    getLocalPlaylists().then((localPlaylists) {
      if (user == null) {
        _playlistsController.add(localPlaylists);
      } else {
        // Reload everything
        _firestore
            .collection('playlists')
            .where('createdBy', isEqualTo: user.uid)
            .orderBy('date', descending: true)
            .get()
            .then((snapshot) {
          final firebasePlaylists = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            data['isLocal'] = false;
            return Playlist.fromJson(data);
          }).toList();

          final firebaseIds = firebasePlaylists.map((p) => p.id).toSet();
          final uniqueLocal =
              localPlaylists.where((p) => !firebaseIds.contains(p.id)).toList();

          final combined = [...firebasePlaylists, ...uniqueLocal];
          combined.sort((a, b) => b.date.compareTo(a.date));

          _playlistsController.add(combined);
        }).catchError((e) {
          if (kDebugMode) {
            print('Error reloading playlists: $e');
          }
          _playlistsController.add(localPlaylists);
        });
      }
    });
  }

  // Get a specific playlist by ID
  Future<Playlist?> getPlaylistById(String id) async {
    try {
      // Check local first
      final localPlaylists = await getLocalPlaylists();
      final local = localPlaylists.where((p) => p.id == id).firstOrNull;
      if (local != null) return local;

      // Check Firebase
      final doc = await _firestore.collection('playlists').doc(id).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        data['id'] = doc.id;
        data['isLocal'] = false;
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
      // Update local
      final localPlaylists = await getLocalPlaylists();
      final index = localPlaylists.indexWhere((p) => p.id == playlistId);

      if (index != -1) {
        final playlist = localPlaylists[index];
        if (!playlist.hymnIds.contains(hymnId)) {
          final updatedHymnIds = [...playlist.hymnIds, hymnId];
          localPlaylists[index] = playlist.copyWith(
            hymnIds: updatedHymnIds,
            updatedAt: DateTime.now(),
          );
          await saveLocalPlaylists(localPlaylists);
          notifyPlaylistsChanged();
        }
      }

      // Sync to Firebase if not local
      final user = _auth.currentUser;
      if (user != null && !playlistId.startsWith('local_')) {
        await _firestore.collection('playlists').doc(playlistId).update({
          'hymnIds': FieldValue.arrayUnion([hymnId]),
          'updatedAt': Timestamp.now(),
        });
      }

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
      // Update local
      final localPlaylists = await getLocalPlaylists();
      final index = localPlaylists.indexWhere((p) => p.id == playlistId);

      if (index != -1) {
        final playlist = localPlaylists[index];
        final updatedHymnIds =
            playlist.hymnIds.where((id) => id != hymnId).toList();
        localPlaylists[index] = playlist.copyWith(
          hymnIds: updatedHymnIds,
          updatedAt: DateTime.now(),
        );
        await saveLocalPlaylists(localPlaylists);
        notifyPlaylistsChanged();
      }

      // Sync to Firebase if not local
      final user = _auth.currentUser;
      if (user != null && !playlistId.startsWith('local_')) {
        await _firestore.collection('playlists').doc(playlistId).update({
          'hymnIds': FieldValue.arrayRemove([hymnId]),
          'updatedAt': Timestamp.now(),
        });
      }

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
      // Delete from local
      final localPlaylists = await getLocalPlaylists();
      localPlaylists.removeWhere((p) => p.id == playlistId);
      await saveLocalPlaylists(localPlaylists);
      notifyPlaylistsChanged();

      // Delete from Firebase if not local
      final user = _auth.currentUser;
      if (user != null && !playlistId.startsWith('local_')) {
        await _firestore.collection('playlists').doc(playlistId).delete();
      }

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
      // Update local
      final localPlaylists = await getLocalPlaylists();
      final index = localPlaylists.indexWhere((p) => p.id == playlistId);

      if (index != -1) {
        localPlaylists[index] = localPlaylists[index].copyWith(
          title: title,
          date: date,
          isPublic: isPublic,
          updatedAt: DateTime.now(),
        );
        await saveLocalPlaylists(localPlaylists);
      }

      // Sync to Firebase if not local
      final user = _auth.currentUser;
      if (user != null && !playlistId.startsWith('local_')) {
        final Map<String, dynamic> updates = {
          'updatedAt': Timestamp.now(),
        };

        if (title != null) updates['title'] = title;
        if (date != null) updates['date'] = Timestamp.fromDate(date);
        if (isPublic != null) updates['isPublic'] = isPublic;

        await _firestore
            .collection('playlists')
            .doc(playlistId)
            .update(updates);
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating playlist: $e');
      }
      return false;
    }
  }

  // Sync local playlists to Firebase (called on login)
  Future<void> syncPlaylistsToFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final prefs = await SharedPreferences.getInstance();
      final isSynced = prefs.getBool(_playlistsSyncedKey) ?? false;

      if (isSynced) return;

      final localPlaylists = await getLocalPlaylists();
      final localOnlyPlaylists =
          localPlaylists.where((p) => p.isLocal).toList();

      if (localOnlyPlaylists.isEmpty) {
        await prefs.setBool(_playlistsSyncedKey, true);
        return;
      }

      final batch = _firestore.batch();
      final updatedPlaylists = <Playlist>[];

      for (var playlist in localOnlyPlaylists) {
        final docRef = _firestore.collection('playlists').doc();
        final playlistData = playlist
            .copyWith(
              id: docRef.id,
              createdBy: user.uid,
              isLocal: false,
            )
            .toFirestore();

        batch.set(docRef, playlistData);
        updatedPlaylists.add(playlist.copyWith(
          id: docRef.id,
          createdBy: user.uid,
          isLocal: false,
        ));
      }

      await batch.commit();

      // Update local storage with new IDs
      final allPlaylists = await getLocalPlaylists();
      for (var updated in updatedPlaylists) {
        final index = allPlaylists.indexWhere((p) =>
            p.title == updated.title && p.date == updated.date && p.isLocal);
        if (index != -1) {
          allPlaylists[index] = updated;
        }
      }
      await saveLocalPlaylists(allPlaylists);

      await prefs.setBool(_playlistsSyncedKey, true);
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing playlists to Firebase: $e');
      }
    }
  }

  // Reset sync status (called on logout)
  Future<void> resetSyncStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_playlistsSyncedKey);
  }
}
