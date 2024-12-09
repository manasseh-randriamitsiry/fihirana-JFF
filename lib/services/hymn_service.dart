import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hymn.dart';
import '../models/favorite.dart';
import '../utility/snackbar_utility.dart';

class HymnService {
  final CollectionReference hymnsCollection =
      FirebaseFirestore.instance.collection('hymns');
  final CollectionReference favoritesCollection =
      FirebaseFirestore.instance.collection('favorites');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String collectionName = 'hymns';

  // Get stream of hymns sorted by hymn number
  Stream<QuerySnapshot> getHymnsStream() {
    return _firestore
        .collection(collectionName)
        .orderBy('hymnNumber', descending: false)
        .snapshots();
  }

  Future<bool> addHymn(Hymn hymn) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        SnackbarUtility.showError(
          title: 'Nisy olana',
          message: 'Mila miditra aloha ianao',
        );
        return false;
      }

      // Check if user has permission to add hymns
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists || !(userDoc.data()?['canAddHymns'] ?? false)) {
        SnackbarUtility.showError(
          title: 'Nisy olana',
          message: 'Tsy manana alalana hanampy hira ianao',
        );
        return false;
      }

      bool isUnique = await _isHymnNumberUnique(hymn.hymnNumber, '');
      if (!isUnique) {
        SnackbarUtility.showError(
          title: 'Nisy olana',
          message: 'Antony : efa misy hira faha: ${hymn.hymnNumber} ',
        );
        return false;
      }

      hymn.createdBy = user.displayName ?? 'Unknown User';
      hymn.createdByEmail = user.email;
      hymn.createdAt = DateTime.now();

      final docData = {
        'hymnNumber': hymn.hymnNumber,
        'title': hymn.title,
        'verses': hymn.verses,
        'bridge': hymn.bridge,
        'hymnHint': hymn.hymnHint,
        'createdAt': Timestamp.fromDate(hymn.createdAt),
        'createdBy': hymn.createdBy,
        'createdByEmail': hymn.createdByEmail,
      };

      await hymnsCollection.add(docData);
      SnackbarUtility.showSuccess(
        title: 'Tafiditra soamantsara',
        message: 'Deraina ny Tompo',
      );
      return true;
    } catch (e) {
      SnackbarUtility.showError(
        title: 'Nisy olana',
        message: 'Antony : efa misy hira faha: ${hymn.hymnNumber} ',
      );
      if (kDebugMode) {
        print('Error adding hymn: $e');
      }
      return false;
    }
  }

  Future<void> updateHymn(String hymnId, Hymn hymn) async {
    try {
      // Check uniqueness, excluding the current hymn being updated
      bool isUnique = await _isHymnNumberUnique(hymn.hymnNumber, hymnId);

      if (!isUnique) {
        SnackbarUtility.showError(
          title: 'Nisy olana',
          message: 'Antony: Efa misy hira faha: ${hymn.hymnNumber}',
        );
        return;
      }

      // Create the document data with Timestamp
      final docData = {
        'hymnNumber': hymn.hymnNumber,
        'title': hymn.title,
        'verses': hymn.verses,
        'bridge': hymn.bridge,
        'hymnHint': hymn.hymnHint,
        'createdAt': Timestamp.fromDate(hymn.createdAt),
        'createdBy': hymn.createdBy,
        'createdByEmail': hymn.createdByEmail,
      };

      // Perform the update
      await hymnsCollection.doc(hymnId).update(docData);

      SnackbarUtility.showSuccess(
        title: 'Vita fanavaozana',
        message: 'Deraina ny Tompo',
      );
    } catch (e) {
      SnackbarUtility.showError(
        title: 'Nisy olana',
        message: 'Antony: Tsy nahomby ny fanavaozana hira ${hymn.hymnNumber}',
      );

      if (kDebugMode) {
        print('Error updating hymn: $e');
      }
    }
  }

  Future<void> deleteHymn(String hymnId) async {
    try {
      await hymnsCollection.doc(hymnId).delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting hymn: $e');
      }
      rethrow;
    }
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final localFavorites = await getLocalFavorites();
      if (localFavorites.isEmpty) return;

      // Get existing cloud favorites
      final querySnapshot =
          await favoritesCollection.where('userId', isEqualTo: user.uid).get();

      final existingFavorites =
          querySnapshot.docs.map((doc) => doc.get('hymnId') as String).toSet();

      // Find favorites that need to be synced
      final favoritesToSync = localFavorites.difference(existingFavorites);

      if (favoritesToSync.isNotEmpty) {
        // Ask user if they want to sync
        final shouldSync = await Get.dialog<bool>(
              AlertDialog(
                title: const Text('Hampiditra ny hira tiana'),
                content: const Text(
                    'Tianao hampidirina any amin\'ny kaontinao ve ireo hira tiana?'),
                actions: [
                  TextButton(
                    child: const Text('Tsia'),
                    onPressed: () => Get.back(result: false),
                  ),
                  TextButton(
                    child: const Text('Eny'),
                    onPressed: () => Get.back(result: true),
                  ),
                ],
              ),
            ) ??
            false;

        if (shouldSync) {
          // Add new favorites to Firebase
          for (final hymnId in favoritesToSync) {
            final favorite = Favorite(
              id: '',
              hymnId: hymnId,
              userId: user.uid,
              userEmail: user.email ?? '',
              addedDate: DateTime.now(),
            );
            await favoritesCollection.add(favorite.toFirestore());
          }

          // Clear local favorites after successful sync
          await saveLocalFavorites(Set<String>());
        }
      }
    } catch (e) {
      print('Error syncing favorites: $e');
    }
  }

  Future<void> checkPendingSyncs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final localFavorites = await getLocalFavorites();
      if (localFavorites.isNotEmpty) {
        await syncLocalFavoritesToFirebase();
      }
    }
  }

  // Single shared stream controller for favorite status
  static final _favoritesController =
      StreamController<Map<String, String>>.broadcast();

  HymnService() {
    _initFavoriteStream();
  }

  void _initFavoriteStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Listen to Firestore changes in real-time
      favoritesCollection
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) {
        _updateFavoriteStatus();
      });
    }
    // Initial load
    _updateFavoriteStatus();
  }

  Future<void> _updateFavoriteStatus() async {
    try {
      final Map<String, String> statuses = {};
      final user = FirebaseAuth.instance.currentUser;
      final localFavorites = await getLocalFavorites();

      if (user != null) {
        final snapshot = await favoritesCollection
            .where('userId', isEqualTo: user.uid)
            .get();

        for (var doc in snapshot.docs) {
          statuses[doc.get('hymnId')] = 'cloud';
        }
      }

      // Add local favorites
      for (var hymnId in localFavorites) {
        if (!statuses.containsKey(hymnId)) {
          statuses[hymnId] = 'local';
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

      final hymnDocs = await hymnsCollection
          .where(FieldPath.documentId, whereIn: favoriteStatus.keys.toList())
          .get();

      return hymnDocs.docs
          .map((doc) =>
              Hymn.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    });
  }

  Future<void> toggleFavorite(Hymn hymn) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final localFavorites = await getLocalFavorites();

      if (user != null) {
        final querySnapshot = await favoritesCollection
            .where('userId', isEqualTo: user.uid)
            .where('hymnId', isEqualTo: hymn.id)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          // Remove from cloud
          for (var doc in querySnapshot.docs) {
            await doc.reference.delete();
          }
          // Remove from local if exists
          if (localFavorites.contains(hymn.id)) {
            localFavorites.remove(hymn.id);
            await saveLocalFavorites(localFavorites);
          }
        } else {
          // Add to cloud
          final favorite = Favorite(
            id: '',
            hymnId: hymn.id,
            userId: user.uid,
            userEmail: user.email ?? '',
            addedDate: DateTime.now(),
          );
          await favoritesCollection.add(favorite.toFirestore());

          // Add to local
          if (!localFavorites.contains(hymn.id)) {
            localFavorites.add(hymn.id);
            await saveLocalFavorites(localFavorites);
          }
        }
      } else {
        // Toggle local only
        if (localFavorites.contains(hymn.id)) {
          localFavorites.remove(hymn.id);
        } else {
          localFavorites.add(hymn.id);
        }
        await saveLocalFavorites(localFavorites);
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final querySnapshot = await favoritesCollection
        .where('userId', isEqualTo: user.uid)
        .where('hymnId', isEqualTo: hymnId)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  Future<bool> _isHymnNumberUnique(String hymnNumber, String hymnId) async {
    try {
      // Query Firestore for hymns with the same hymnNumber
      final querySnapshot = await FirebaseFirestore.instance
          .collection('hymns')
          .where('hymnNumber', isEqualTo: hymnNumber)
          .get();

      // Count documents with the same hymnNumber but a different id
      int count = querySnapshot.docs.where((doc) => doc.id != hymnId).length;

      // If count > 0, there's a duplicate
      return count == 0;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking hymn uniqueness: $e');
      }
      return false; // Assume not unique if an error occurs
    }
  }
}
