import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hymn.dart';
import '../models/favorite.dart';
import '../utility/snackbar_utility.dart';
import 'local_hymn_service.dart';

class HymnService {
  final LocalHymnService _localHymnService = LocalHymnService();

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
    // This functionality is not needed with local files
    // But we keep it for compatibility
  }

  Future<void> checkPendingSyncs() async {
    // This functionality is not needed with local files
    // But we keep it for compatibility
  }

  // Single shared stream controller for favorite status
  static final _favoritesController =
      StreamController<Map<String, String>>.broadcast();

  HymnService() {
    _initFavoriteStream();
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

      // Toggle local only
      if (localFavorites.contains(hymn.id)) {
        localFavorites.remove(hymn.id);
      } else {
        localFavorites.add(hymn.id);
      }
      await saveLocalFavorites(localFavorites);

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
    return localFavorites.contains(hymnId);
  }
}
