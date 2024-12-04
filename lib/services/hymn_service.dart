import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/hymn.dart';
import '../models/favorite.dart';

class HymnService {
  final CollectionReference hymnsCollection =
      FirebaseFirestore.instance.collection('hymns');
  final CollectionReference favoritesCollection =
      FirebaseFirestore.instance.collection('favorites');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String collectionName = 'hymns';

  // Get stream of hymns sorted by hymn number
  Stream<QuerySnapshot> getHymnsStream() {
    return _firestore.collection(collectionName)
        .orderBy('hymnNumber', descending: false)
        .snapshots();
  }

  Future<bool> addHymn(Hymn hymn) async {
    try {
      bool isUnique = await _isHymnNumberUnique(hymn.hymnNumber, '');
      if (!isUnique) {
        _showErrorSnackbar(
          title: 'Nisy olana',
          message: 'Antony : efa misy hira faha: ${hymn.hymnNumber} ',
        );
        return false;
      }

      // Format hymn number to ensure consistent sorting
      String numStr = hymn.hymnNumber.replaceAll(RegExp(r'[^0-9]'), '');
      int hymnNum = int.tryParse(numStr) ?? 0;
      // Pad with zeros to ensure proper sorting (e.g., "001", "002", etc.)
      hymn.hymnNumber = hymnNum.toString().padLeft(3, '0');

      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      hymn.createdBy = user?.displayName ?? 'Unknown User';
      hymn.createdByEmail = user?.email;
      hymn.createdAt = DateTime.now();

      // Perform addition
      await hymnsCollection.add(hymn.toFirestore());
      _showSuccessSnackbar(
        title: 'Tafiditra soamantsara',
        message: 'Deraina ny Tompo',
      );
      return true;
    } catch (e) {
      _showErrorSnackbar(
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
      // Check if hymnNumber is unique (excluding the current hymn being updated)
      bool isUnique = await _isHymnNumberUnique(hymn.hymnNumber, hymnId);

      if (!isUnique) {
        _showErrorSnackbar(
          title: 'Nisy olana',
          message: 'Antony: Efa misy hira faha: ${hymn.hymnNumber}',
        );
        return;
      }

      // Format hymn number consistently
      String numStr = hymn.hymnNumber.replaceAll(RegExp(r'[^0-9]'), '');
      int hymnNum = int.tryParse(numStr) ?? 0;
      hymn.hymnNumber = hymnNum.toString().padLeft(3, '0');

      // Perform the update operation
      await hymnsCollection.doc(hymnId).update(hymn.toFirestore());

      // Show success message
      _showSuccessSnackbar(
        title: 'Vita fanavaozana',
        message: 'Deraina ny Tompo',
      );
    } catch (e) {
      // Handle errors
      _showErrorSnackbar(
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
    final prefs = await SharedPreferences.getInstance();
    return Set<String>.from(prefs.getStringList('local_favorites') ?? []);
  }

  Future<void> saveLocalFavorites(Set<String> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('local_favorites', favorites.toList());
  }

  Future<void> syncLocalFavoritesToFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final localFavorites = await getLocalFavorites();
      if (localFavorites.isEmpty) return;

      // Get existing cloud favorites
      final querySnapshot = await favoritesCollection
          .where('userId', isEqualTo: user.uid)
          .get();
      
      final existingFavorites = querySnapshot.docs
          .map((doc) => doc.get('hymnId') as String)
          .toSet();

      // Find favorites that need to be synced
      final favoritesToSync = localFavorites.difference(existingFavorites);

      if (favoritesToSync.isNotEmpty) {
        // Ask user if they want to sync
        final shouldSync = await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Hampiditra ny hira tiana'),
            content: const Text('Tianao hampidirina any amin\'ny kaontinao ve ireo hira tiana?'),
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
        ) ?? false;

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

  Stream<List<String>> getFavoriteHymnIdsStream() async* {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      // If user is logged in, sync local favorites first
      await syncLocalFavoritesToFirebase();
      
      // Then stream Firebase favorites
      yield* favoritesCollection
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => doc.get('hymnId') as String)
              .toList());
    } else {
      // If no user, stream local favorites
      final localFavorites = await getLocalFavorites();
      yield localFavorites.toList();
    }
  }

  Stream<List<Hymn>> getFavoriteHymnsStream() {
    return getFavoriteHymnIdsStream().asyncMap((favoriteIds) async {
      if (favoriteIds.isEmpty) return [];

      final hymnDocs = await hymnsCollection
          .where(FieldPath.documentId, whereIn: favoriteIds)
          .get();

      return hymnDocs.docs
          .map((doc) => Hymn.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    });
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

  Future<void> toggleFavorite(Hymn hymn) async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      // Handle Firebase favorites
      try {
        final isFavorite = await isHymnFavorite(hymn.id);
        
        if (isFavorite) {
          // Remove from Firebase favorites
          final querySnapshot = await favoritesCollection
              .where('userId', isEqualTo: user.uid)
              .where('hymnId', isEqualTo: hymn.id)
              .get();
              
          for (var doc in querySnapshot.docs) {
            await doc.reference.delete();
          }
        } else {
          // Add to Firebase favorites
          final favorite = Favorite(
            id: '',
            hymnId: hymn.id,
            userId: user.uid,
            userEmail: user.email ?? '',
            addedDate: DateTime.now(),
          );
          await favoritesCollection.add(favorite.toFirestore());
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error toggling Firebase favorite: $e');
        }
        rethrow;
      }
    } else {
      // Handle local favorites
      try {
        final localFavorites = await getLocalFavorites();
        if (localFavorites.contains(hymn.id)) {
          localFavorites.remove(hymn.id);
        } else {
          localFavorites.add(hymn.id);
        }
        await saveLocalFavorites(localFavorites);
      } catch (e) {
        if (kDebugMode) {
          print('Error toggling local favorite: $e');
        }
        rethrow;
      }
    }
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

  void _showErrorSnackbar({required String title, required String message}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  void _showSuccessSnackbar({required String title, required String message}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }
}
