import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fihirana/models/hymn.dart';
import 'package:fihirana/services/data/firebase_sync_service.dart';

class FavoritesService {
  final FirebaseSyncService _firebaseSyncService;
  final FirebaseAuth _auth;
  final Future<List<Hymn>> Function() _getAllHymns;
  final Future<Hymn?> Function(String) _getHymnById;

  static final _favoritesController =
      StreamController<Map<String, String>>.broadcast();

  FavoritesService({
    required FirebaseSyncService firebaseSyncService,
    required FirebaseAuth auth,
    required Future<List<Hymn>> Function() getAllHymns,
    required Future<Hymn?> Function(String) getHymnById,
  })  : _firebaseSyncService = firebaseSyncService,
        _auth = auth,
        _getAllHymns = getAllHymns,
        _getHymnById = getHymnById {
    _initFavoriteStream();

    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _updateFavoriteStatus();
      } else {
        _firebaseSyncService.resetSyncStatus();
        _updateFavoriteStatus();
      }
    });
  }

  void _initFavoriteStream() {
    _updateFavoriteStatus();
  }

  Future<void> _updateFavoriteStatus() async {
    try {
      final Map<String, String> statuses = {};
      final localFavorites = await getLocalFavorites();

      for (var hymnId in localFavorites) {
        statuses[hymnId] = 'local';
      }

      final user = _auth.currentUser;
      if (user != null) {
        final firebaseFavorites =
            await _firebaseSyncService.loadFavoritesFromFirebase();
        for (var hymnId in firebaseFavorites) {
          statuses[hymnId] = 'firebase';
        }
      }

      _favoritesController.add(statuses);
    } catch (e) {
      return;
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
    return getFavoriteStatusStream().transform(
      StreamTransformer.fromHandlers(
        handleData: (favoriteStatus, sink) async {
          if (favoriteStatus.isEmpty) {
            sink.add([]);
            return;
          }

          try {
            final List<Hymn> favoriteHymns = [];
            for (final hymnId in favoriteStatus.keys) {
              final hymn = await _getHymnById(hymnId);
              if (hymn != null) {
                favoriteHymns.add(hymn);
              }
            }
            sink.add(favoriteHymns);
          } catch (e) {
            sink.addError(e);
          }
        },
      ),
    );
  }

  Future<void> toggleFavorite(Hymn hymn) async {
    try {
      final localFavorites = await getLocalFavorites();
      final user = _auth.currentUser;
      bool isCurrentlyFavorite = localFavorites.contains(hymn.id);

      if (isCurrentlyFavorite) {
        localFavorites.remove(hymn.id);
        await saveLocalFavorites(localFavorites);

        if (user != null) {
          await _firebaseSyncService.removeFavoriteFromFirebase(hymn.id);
        }
      } else {
        localFavorites.add(hymn.id);
        await saveLocalFavorites(localFavorites);

        if (user != null) {
          await _firebaseSyncService.addFavoriteToFirebase(hymn.id);
        }
      }

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

    if (localFavorites.contains(hymnId)) {
      return true;
    }

    if (user != null) {
      final firebaseFavorites =
          await _firebaseSyncService.loadFavoritesFromFirebase();
      return firebaseFavorites.contains(hymnId);
    }

    return false;
  }

  Future<Set<String>> getLocalFavorites() async {
    try {
      final completer = Completer<Set<String>>();

      SchedulerBinding.instance.scheduleTask(() async {
        final prefs = await SharedPreferences.getInstance();
        final favorites =
            Set<String>.from(prefs.getStringList('local_favorites') ?? []);
        completer.complete(favorites);
      }, Priority.animation);

      return completer.future;
    } catch (e) {
      if (kDebugMode) {}
      return <String>{};
    }
  }

  Future<void> saveLocalFavorites(Set<String> favorites) async {
    try {
      final completer = Completer<void>();

      SchedulerBinding.instance.scheduleTask(() async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('local_favorites', favorites.toList());
        completer.complete();
      }, Priority.animation);

      return completer.future;
    } catch (e) {
      return;
    }
  }

  Future<List<Hymn>> getFavoriteHymns() async {
    final allHymns = await _getAllHymns();
    final favoriteIds = await getLocalFavorites();
    return allHymns.where((hymn) => favoriteIds.contains(hymn.id)).toList();
  }

  Future<void> addToFavorites(String hymnId) async {
    final favorites = await getLocalFavorites();
    if (!favorites.contains(hymnId)) {
      favorites.add(hymnId);
      await saveLocalFavorites(favorites);
      await _updateFavoriteStatus();
    }
  }

  Future<void> removeFromFavorites(String hymnId) async {
    final favorites = await getLocalFavorites();
    favorites.remove(hymnId);
    await saveLocalFavorites(favorites);
    await _updateFavoriteStatus();
  }

  Future<bool> isFavorite(String hymnId) async {
    final favoriteIds = await getLocalFavorites();
    return favoriteIds.contains(hymnId);
  }
}