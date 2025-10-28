import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/favorite.dart';

class FirebaseSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const String _localFavoritesKey = 'local_favorites';
  static const String _localHistoryKey = 'local_hymn_history';
  static const String _favoritesSyncedKey = 'favorites_synced';
  static const String _historySyncedKey = 'history_synced';

  /// Sync local favorites to Firebase for authenticated users
  Future<void> syncFavoritesToFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final prefs = await SharedPreferences.getInstance();
      final isSynced = prefs.getBool(_favoritesSyncedKey) ?? false;
      
      if (isSynced) {
        return;
      }

      // Get local favorites
      final localFavoritesJson = prefs.getString(_localFavoritesKey);
      if (localFavoritesJson == null) {
        await prefs.setBool(_favoritesSyncedKey, true);
        return;
      }

      final List<dynamic> localFavorites = json.decode(localFavoritesJson);
      if (localFavorites.isEmpty) {
        await prefs.setBool(_favoritesSyncedKey, true);
        return;
      }


      // Get existing Firebase favorites to avoid duplicates
      final firebaseFavoritesSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .get();

      final existingHymnIds = firebaseFavoritesSnapshot.docs
          .map((doc) => doc.data()['hymnId'] as String)
          .toSet();

      // Add new favorites to Firebase
      final batch = _firestore.batch();
      int addedCount = 0;

      for (var hymnId in localFavorites) {
        if (hymnId is String && !existingHymnIds.contains(hymnId)) {
          final favoriteRef = _firestore
              .collection('users')
              .doc(user.uid)
              .collection('favorites')
              .doc();

          final favorite = Favorite(
            id: favoriteRef.id,
            hymnId: hymnId,
            userId: user.uid,
            userEmail: user.email ?? '',
            addedDate: DateTime.now(),
          );

          batch.set(favoriteRef, favorite.toFirestore());
          addedCount++;
        }
      }

      if (addedCount > 0) {
        await batch.commit();
      }

      // Mark as synced
      await prefs.setBool(_favoritesSyncedKey, true);
    } catch (e) {
    }
  }

  /// Sync local history to Firebase for authenticated users
  Future<void> syncHistoryToFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final prefs = await SharedPreferences.getInstance();
      final isSynced = prefs.getBool(_historySyncedKey) ?? false;
      
      if (isSynced) {
        return;
      }

      // Get local history
      final localHistoryJson = prefs.getString(_localHistoryKey);
      if (localHistoryJson == null) {
        await prefs.setBool(_historySyncedKey, true);
        return;
      }

      final List<dynamic> localHistory = json.decode(localHistoryJson);
      if (localHistory.isEmpty) {
        await prefs.setBool(_historySyncedKey, true);
        return;
      }


      // Get existing Firebase history to avoid duplicates
      final firebaseHistorySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .limit(50) // Limit to avoid too many documents
          .get();

      final existingHymnIds = firebaseHistorySnapshot.docs
          .map((doc) => doc.data()['hymnId'] as String)
          .toSet();

      // Add new history items to Firebase (limit to recent items)
      final batch = _firestore.batch();
      int addedCount = 0;
      int maxItemsToSync = 50; // Limit the number of items to sync
      int itemsSynced = 0;

      // Process in reverse order to get most recent items first
      for (var i = localHistory.length - 1; i >= 0 && itemsSynced < maxItemsToSync; i--) {
        final item = localHistory[i];
        if (item is Map<String, dynamic>) {
          final hymnId = item['hymnId'] as String?;
          if (hymnId != null && !existingHymnIds.contains(hymnId)) {
            final historyRef = _firestore
                .collection('users')
                .doc(user.uid)
                .collection('history')
                .doc();

            batch.set(historyRef, {
              'hymnId': hymnId,
              'title': item['title'] as String? ?? '',
              'number': item['number'] as String? ?? '',
              'timestamp': FieldValue.serverTimestamp(),
            });

            addedCount++;
            itemsSynced++;
          }
        }
      }

      if (addedCount > 0) {
        await batch.commit();
      }

      // Mark as synced
      await prefs.setBool(_historySyncedKey, true);
    } catch (e) {
    }
  }

  /// Load favorites from Firebase for authenticated users
  Future<Set<String>> loadFavoritesFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return <String>{};

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .get();

      final favorites = <String>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final hymnId = data['hymnId'] as String?;
        if (hymnId != null) {
          favorites.add(hymnId);
        }
      }

      return favorites;
    } catch (e) {
      return <String>{};
    }
  }

  /// Load history from Firebase for authenticated users
  Future<List<Map<String, dynamic>>> loadHistoryFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .limit(100) // Limit to 100 most recent items
          .get();

      final history = <Map<String, dynamic>>[];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        history.add({
          'id': doc.id,
          'hymnId': data['hymnId'] as String? ?? '',
          'title': data['title'] as String? ?? '',
          'number': data['number'] as String? ?? '',
          'timestamp': (data['timestamp'] as Timestamp).toDate(),
        });
      }

      return history;
    } catch (e) {
      return [];
    }
  }

  /// Add a favorite to Firebase
  Future<void> addFavoriteToFirebase(String hymnId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Check if favorite already exists
      final existingSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .where('hymnId', isEqualTo: hymnId)
          .limit(1)
          .get();

      if (existingSnapshot.docs.isNotEmpty) {
        return;
      }

      final favoriteRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc();

      final favorite = Favorite(
        id: favoriteRef.id,
        hymnId: hymnId,
        userId: user.uid,
        userEmail: user.email ?? '',
        addedDate: DateTime.now(),
      );

      await favoriteRef.set(favorite.toFirestore());
    } catch (e) {
    }
  }

  /// Remove a favorite from Firebase
  Future<void> removeFavoriteFromFirebase(String hymnId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .where('hymnId', isEqualTo: hymnId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.delete();
      }
    } catch (e) {
    }
  }

  /// Add a history item to Firebase
  Future<void> addHistoryToFirebase(String hymnId, String title, String number) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final historyRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('history')
          .doc();

      await historyRef.set({
        'hymnId': hymnId,
        'title': title,
        'number': number,
        'timestamp': FieldValue.serverTimestamp(),
      });

    } catch (e) {
    }
  }

  /// Clear history from Firebase
  Future<void> clearHistoryFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('history')
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
    }
  }

  /// Reset sync status (useful when user logs out)
  Future<void> resetSyncStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_favoritesSyncedKey);
    await prefs.remove(_historySyncedKey);
  }
}