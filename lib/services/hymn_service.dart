import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/hymn.dart';
import '../models/favorite.dart';
import '../utility/snackbar_utility.dart';
import '../services/firebase_sync_service.dart'; // Add Firebase sync service
import 'local_hymn_service.dart';

class HymnService {
  final LocalHymnService _localHymnService = LocalHymnService();
  final FirebaseSyncService _firebaseSyncService = FirebaseSyncService(); // Add Firebase sync service
  final FirebaseAuth _auth = FirebaseAuth.instance; // Add FirebaseAuth

  // Get stream of hymns sorted by hymn number (using local service)
  Stream<List<Hymn>> getHymnsStream() async* {
    final hymns = await _localHymnService.getAllHymns();
    yield hymns;
  }

  Future<Hymn?> getHymnById(String hymnId) async {
    return await _localHymnService.getHymnById(hymnId);
  }

  Future<List<Hymn>> searchHymns(String query) async {
    return await _localHymnService.searchHymns(query);
  }

  Future<bool> addHymn(Hymn hymn) async {
    // This functionality is not available with local files
    SnackbarUtility.showError(
      title: 'Tsy misy alalana',
      message: 'Tsy afaka manampy hira amin\'izao fotoana izao',
    );
    return false;
  }

  Future<void> updateHymn(String hymnId, Hymn hymn) async {
    // This functionality is not available with local files
    SnackbarUtility.showError(
      title: 'Tsy misy alalana',
      message: 'Tsy afaka manova hira amin\'izao fotoana izao',
    );
  }

  Future<void> deleteHymn(String hymnId) async {
    // This functionality is not available with local files
    SnackbarUtility.showError(
      title: 'Tsy misy alalana',
      message: 'Tsy afaka mamafa hira amin\'izao fotoana izao',
    );
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
        print('Error getting local favorites: $e');
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
        print('Error saving local favorites: $e');
      }
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
      print('Error updating favorite status: $e');
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
        final hymn = await _localHymnService.getHymnById(hymnId);
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
      print('Error toggling favorite: $e');
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
}