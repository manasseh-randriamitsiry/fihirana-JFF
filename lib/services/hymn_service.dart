import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hymn.dart';
import '../utility/snackbar_utility.dart';
import '../services/firebase_sync_service.dart';
import 'local_hymn_service.dart';

class HymnService {
  final LocalHymnService _localHymnService = LocalHymnService();
  final FirebaseSyncService _firebaseSyncService = FirebaseSyncService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get stream of local hymns only
  Stream<List<Hymn>> getLocalHymnsStream() async* {
    final hymns = await _localHymnService.getAllHymns();
    yield hymns;
  }

  // Get stream of Firebase hymns (reactive to changes)
  Stream<List<Hymn>> getFirebaseHymnsStream() {
    return _firestore.collection('hymns').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Hymn.fromJson(data, doc.id);
      }).toList();
    });
  }

  Future<List<Hymn>> _getFirebaseHymns() async {
    try {
      final snapshot = await _firestore.collection('hymns').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Hymn.fromJson(data, doc.id);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Hymn?> getHymnById(String hymnId) async {
    // First try to get from local
    var hymn = await _localHymnService.getHymnById(hymnId);
    if (hymn != null) return hymn;
    
    // If not found locally, try Firebase
    try {
      final doc = await _firestore.collection('hymns').doc(hymnId).get();
      if (doc.exists) {
        return Hymn.fromJson(doc.data()!, doc.id);
      }
    } catch (e) {
      // Handle error
    }
    
    return null;
  }

  Future<List<Hymn>> searchHymns(String query) async {
    // Search in local hymns only for now
    return await _localHymnService.searchHymns(query);
  }

  Future<bool> addHymn(Hymn hymn) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        SnackbarUtility.showError(
          title: 'Tsy misy fifandraisan-tsara',
          message: 'Mila miditra aloha ianao mba hahafahana manampy hira',
        );
        return false;
      }

      // Set created by information
      hymn.createdBy = user.displayName ?? user.email ?? 'Unknown User';
      hymn.createdByEmail = user.email;

      // Add to Firebase
      final docRef = await _firestore.collection('hymns').add(hymn.toMap());
      
      // Update the hymn ID with the document ID
      hymn.id = docRef.id;
      await docRef.update({'id': docRef.id});

      SnackbarUtility.showSuccess(
        title: 'Vita soa aman-tsara',
        message: 'Voapetraha soa aman-tsara ny hira',
      );
      
      return true;
    } catch (e) {
      SnackbarUtility.showError(
        title: 'Nisy olana',
        message: 'Tsy afaka napetraka ny hira: $e',
      );
      return false;
    }
  }

  Future<void> updateHymn(String hymnId, Hymn hymn) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        SnackbarUtility.showError(
          title: 'Tsy misy fifandraisan-tsara',
          message: 'Mila miditra aloha ianao mba hahafahana manova hira',
        );
        return;
      }

      await _firestore.collection('hymns').doc(hymnId).update(hymn.toMap());
      
      SnackbarUtility.showSuccess(
        title: 'Vita soa aman-tsara',
        message: 'Nohavaozina soa aman-tsara ny hira',
      );
    } catch (e) {
      SnackbarUtility.showError(
        title: 'Nisy olana',
        message: 'Tsy afaka novaozina ny hira: $e',
      );
    }
  }

  Future<void> deleteHymn(String hymnId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        SnackbarUtility.showError(
          title: 'Tsy misy fifandraisan-tsara',
          message: 'Mila miditra aloha ianao mba hahafahana mamafa hira',
        );
        return;
      }

      await _firestore.collection('hymns').doc(hymnId).delete();
      
      SnackbarUtility.showSuccess(
        title: 'Vita soa aman-tsara',
        message: 'Voafafa soa aman-tsara ny hira',
      );
    } catch (e) {
      SnackbarUtility.showError(
        title: 'Nisy olana',
        message: 'Tsy afaka voafafa ny hira: $e',
      );
    }
  }

  Future<void> syncLocalFavoritesToFirebase() async {
    await _firebaseSyncService.syncFavoritesToFirebase();
  }

  Future<void> checkPendingSyncs() async {
    await _firebaseSyncService.syncFavoritesToFirebase();
    await _firebaseSyncService.syncHistoryToFirebase();
  }

  // Single shared stream controller for favorite status
  static final _favoritesController =
      StreamController<Map<String, String>>.broadcast();

  HymnService() {
    _initFavoriteStream();
    // Listen to auth state changes to sync data when user logs in
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // User logged in, sync data
        checkPendingSyncs();
        // Refresh favorite status
        _updateFavoriteStatus();
      } else {
        // User logged out, reset sync status
        _firebaseSyncService.resetSyncStatus();
        // Refresh favorite status
        _updateFavoriteStatus();
      }
    });
  }

  void _initFavoriteStream() {
    // Initialize with empty favorites or load from local storage
    _updateFavoriteStatus();
  }

  Future<void> _updateFavoriteStatus() async {
    try {
      final Map<String, String> statuses = {};
      final localFavorites = await getLocalFavorites();

      // Add local favorites
      for (var hymnId in localFavorites) {
        statuses[hymnId] = 'local';
      }

      // If user is authenticated, also load Firebase favorites
      final user = _auth.currentUser;
      if (user != null) {
        final firebaseFavorites = await _firebaseSyncService.loadFavoritesFromFirebase();
        for (var hymnId in firebaseFavorites) {
          statuses[hymnId] = 'firebase';
        }
      }

      _favoritesController.add(statuses);
    } catch (e) {
    }
  }

  Stream<Map<String, String>> getFavoriteStatusStream() {
    return _favoritesController.stream;
  }

  Stream<List<String>> getFavoriteHymnIdsStream() {
    return getFavoriteStatusStream()
        .map((statusMap) => statusMap.keys.toList());
  }

  Stream<List<Hymn>> getFavoriteHymnsStream() {
    return getFavoriteStatusStream().asyncMap((favoriteStatus) async {
      if (favoriteStatus.isEmpty) return [];

      final List<Hymn> favoriteHymns = [];
      for (final hymnId in favoriteStatus.keys) {
        final hymn = await getHymnById(hymnId);
        if (hymn != null) {
          favoriteHymns.add(hymn);
        }
      }

      return favoriteHymns;
    });
  }

  Future<void> toggleFavorite(Hymn hymn) async {
    try {
      final localFavorites = await getLocalFavorites();
      final user = _auth.currentUser;
      bool isCurrentlyFavorite = localFavorites.contains(hymn.id);

      if (isCurrentlyFavorite) {
        // Remove from favorites
        localFavorites.remove(hymn.id);
        await saveLocalFavorites(localFavorites);
        
        // Remove from Firebase if user is authenticated
        if (user != null) {
          await _firebaseSyncService.removeFavoriteFromFirebase(hymn.id);
        }
      } else {
        // Add to favorites
        localFavorites.add(hymn.id);
        await saveLocalFavorites(localFavorites);
        
        // Add to Firebase if user is authenticated
        if (user != null) {
          await _firebaseSyncService.addFavoriteToFirebase(hymn.id);
        }
      }
      
      // Update status after changes
      await _updateFavoriteStatus();
    } catch (e) {
      rethrow;
    }
  }

  void dispose() {
    _favoritesController.close();
  }

  Future<bool> isHymnFavorite(String hymnId) async {
    final localFavorites = await getLocalFavorites();
    final user = _auth.currentUser;
    
    // Check local favorites first
    if (localFavorites.contains(hymnId)) {
      return true;
    }
    
    // If user is authenticated, also check Firebase
    if (user != null) {
      final firebaseFavorites = await _firebaseSyncService.loadFavoritesFromFirebase();
      return firebaseFavorites.contains(hymnId);
    }
    
    return false;
  }

  Future<Set<String>> getLocalFavorites() async {
    try {
      final completer = Completer<Set<String>>();

      // Schedule the SharedPreferences operation
      SchedulerBinding.instance.scheduleTask(() async {
        final prefs = await SharedPreferences.getInstance();
        final favorites =
            Set<String>.from(prefs.getStringList('local_favorites') ?? []);
        completer.complete(favorites);
      }, Priority.animation);

      return completer.future;
    } catch (e) {
      if (kDebugMode) {
      }
      return <String>{};
    }
  }

  Future<void> saveLocalFavorites(Set<String> favorites) async {
    try {
      final completer = Completer<void>();

      // Schedule the SharedPreferences operation
      SchedulerBinding.instance.scheduleTask(() async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('local_favorites', favorites.toList());
        completer.complete();
      }, Priority.animation);

      return completer.future;
    } catch (e) {
      if (kDebugMode) {
      }
    }
  }
}