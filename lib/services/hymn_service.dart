import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hymn.dart';
import '../utility/snackbar_utility.dart';
import '../services/firebase_sync_service.dart';
import 'combined_hymn_service.dart';

class HymnService {
  final CombinedHymnService _combinedHymnService = CombinedHymnService();
  final FirebaseSyncService _firebaseSyncService = FirebaseSyncService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Hymn>> getLocalHymnsStream() async* {
    final hymns = await _combinedHymnService.getAllHymns();
    yield hymns;
  }

  Stream<List<Hymn>> getFirebaseHymnsStream() {
    return _firestore.collection('hymns').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Hymn.fromJson(data, doc.id);
      }).toList();
    });
  }

  Future<List<Hymn>> getAllHymns() async {
    return await _combinedHymnService.getAllHymns();
  }

  Future<Hymn?> getHymnById(String hymnId) async {
    var hymn = await _combinedHymnService.getHymnById(hymnId);
    if (hymn != null) return hymn;

    try {
      final doc = await _firestore.collection('hymns').doc(hymnId).get();
      if (doc.exists) {
        return Hymn.fromJson(doc.data()!, doc.id);
      }
    } catch (e) {
      return null;
    }

    return null;
  }

  Future<List<Hymn>> searchHymns(String query) async {
    return await _combinedHymnService.searchHymns(query);
  }

  Future<List<Hymn>> getHymnsByIds(List<String> ids) async {
    final List<Hymn> hymns = [];
    for (final id in ids) {
      final hymn = await getHymnById(id);
      if (hymn != null) {
        hymns.add(hymn);
      }
    }
    return hymns;
  }

  Future<DateTime> _getServerTime() async {
    try {
      final response = await http.head(Uri.parse('https://www.google.com'));
      if (response.headers['date'] != null) {
        return HttpDate.parse(response.headers['date']!);
      }
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
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

      // Get server time to prevent local time manipulation
      final now = await _getServerTime();
      final currentMonth = now.toString().substring(0, 7); // Format: YYYY-MM

      // Get current user data to check limit
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      if (userData != null) {
        final lastMonth = userData['lastHymnAdditionMonth'] as String? ?? '';
        final monthlyCount = userData['monthlyHymnCount'] as int? ?? 0;
        final isAdmin = userData['isAdmin'] as bool? ?? false;

        // Check limit if not admin
        if (!isAdmin) {
          if (lastMonth == currentMonth && monthlyCount >= 5) {
            SnackbarUtility.showError(
              title: 'Fetra tratra',
              message:
                  'Efa feno ny fetra 5 hira isam-bolana. Miandrasa volana manaraka.',
            );
            return false;
          }
        }

        hymn.createdBy = user.displayName ?? user.email ?? 'Unknown User';
        hymn.createdByEmail = user.email;

        final docRef = await _firestore.collection('hymns').add(hymn.toMap());

        hymn.id = docRef.id;
        await docRef.update({'id': docRef.id});

        // Prepare update data
        final Map<String, dynamic> updateData = {
          'addedHymnsCount': FieldValue.increment(1),
        };

        if (lastMonth != currentMonth) {
          // New month, reset counter
          updateData['monthlyHymnCount'] = 1;
          updateData['lastHymnAdditionMonth'] = currentMonth;
        } else {
          // Same month, increment counter
          updateData['monthlyHymnCount'] = FieldValue.increment(1);
        }

        await _firestore.collection('users').doc(user.uid).update(updateData);

        SnackbarUtility.showSuccess(
          title: 'Vita soa aman-tsara',
          message: 'Voapetraha soa aman-tsara ny hira',
        );

        return true;
      }
      return false;
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

  static final _favoritesController =
      StreamController<Map<String, String>>.broadcast();

  HymnService() {
    _initFavoriteStream();

    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        checkPendingSyncs();

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
              final hymn = await getHymnById(hymnId);
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
}
