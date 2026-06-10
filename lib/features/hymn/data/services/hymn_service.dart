import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/core/utils/firebase_sync_service.dart';
import 'package:fihirana/features/hymn/domain/repositories/hymn_repository.dart';
import 'package:fihirana/core/utils/local_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'combined_hymn_service.dart';
import 'package:fihirana/features/hymn/data/services/favorites_service.dart';
import 'package:fihirana/features/hymn/data/services/firebase_hymn_service.dart';

class HymnService implements IHymnService {
  final CombinedHymnService _combinedHymnService = CombinedHymnService();
  final FirebaseSyncService _firebaseSyncService = FirebaseSyncService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalStorageService _localStorageService = LocalStorageService();

  late final FavoritesService _favoritesService;
  late final FirebaseHymnService _firebaseHymnService;

  Stream<List<Hymn>> getLocalHymnsStream() async* {
    final hymns = await _combinedHymnService.getAllHymns();
    yield hymns;
  }

  Stream<List<Hymn>> getFirebaseHymnsStream() {
    return _firebaseHymnService.getFirebaseHymnsStream();
  }

  @override
  Future<List<Hymn>> getAllHymns() async {
    return await _combinedHymnService.getAllHymns();
  }

  @override
  Future<Hymn?> getHymnById(String id) async {
    return await _combinedHymnService.getHymnById(id);
  }

  Future<Hymn?> getHymnByIdAsync(String hymnId) async {
    var hymn = await _combinedHymnService.getHymnById(hymnId);
    if (hymn != null) return hymn;

    return await _firebaseHymnService.getHymnByIdFromFirebase(hymnId);
  }

  @override
  Future<List<Hymn>> searchHymns(String query) async {
    return await _combinedHymnService.searchHymns(query);
  }

  Future<List<Hymn>> getHymnsByIds(List<String> ids) async {
    final futures = ids.map(getHymnById);
    final results = await Future.wait(futures);
    return results.where((hymn) => hymn != null).cast<Hymn>().toList();
  }

  Future<void> toggleFavorite(Hymn hymn) async {
    await _favoritesService.toggleFavorite(hymn);
  }

  Stream<Map<String, String>> getFavoriteStatusStream() {
    return _favoritesService.getFavoriteStatusStream();
  }

  Map<String, String> get currentFavoriteStatus =>
      _favoritesService.currentFavoriteStatus;

  Stream<List<String>> getFavoriteHymnIdsStream() {
    return _favoritesService.getFavoriteHymnIdsStream();
  }

  Stream<List<Hymn>> getFavoriteHymnsStream() {
    return _favoritesService.getFavoriteHymnsStream();
  }

  Future<bool> isHymnFavorite(String hymnId) async {
    return _favoritesService.isHymnFavorite(hymnId);
  }

  Future<bool> addHymn(Hymn hymn) async {
    return await _firebaseHymnService.addHymn(hymn);
  }

  Future<void> updateHymn(String hymnId, Hymn hymn) async {
    await _firebaseHymnService.updateHymn(hymnId, hymn);
  }

  Future<void> deleteHymn(String hymnId) async {
    await _firebaseHymnService.deleteHymn(hymnId);
  }

  Future<void> syncLocalFavoritesToFirebase() async {
    await _firebaseSyncService.syncFavoritesToFirebase();
  }

  Future<void> checkPendingSyncs() async {
    await _firebaseSyncService.syncFavoritesToFirebase();
    await _firebaseSyncService.syncHistoryToFirebase();
  }

  static final HymnService _instance = HymnService._internal();

  factory HymnService() {
    return _instance;
  }

  HymnService._internal() {
    _favoritesService = FavoritesService(
      firebaseSyncService: _firebaseSyncService,
      auth: _auth,
      getAllHymns: getAllHymns,
      getHymnById: getHymnById,
    );

    _firebaseHymnService = FirebaseHymnService(
      auth: _auth,
      firestore: _firestore,
    );

    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        checkPendingSyncs();
      } else {
        _firebaseSyncService.resetSyncStatus();
      }
    });
  }

  void dispose() {
    _favoritesService.dispose();
  }

  @override
  Future<Hymn?> getHymnByTitle(String title) async {
    final allHymns = await getAllHymns();
    try {
      return allHymns.firstWhere(
          (hymn) => hymn.title.toLowerCase() == title.toLowerCase());
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Hymn>> getHymnsByCategory(String category) async {
    final allHymns = await getAllHymns();
    return allHymns.where((hymn) => hymn.title.contains(category)).toList();
  }

  @override
  Future<List<Hymn>> getHymnsByAuthor(String author) async {
    final allHymns = await getAllHymns();
    return allHymns.where((hymn) => hymn.createdBy == author).toList();
  }

  @override
  Future<List<Hymn>> getFavoriteHymns() async {
    return _favoritesService.getFavoriteHymns();
  }

  @override
  Future<void> addToFavorites(String hymnId) async {
    await _favoritesService.addToFavorites(hymnId);
  }

  @override
  Future<void> removeFromFavorites(String hymnId) async {
    await _favoritesService.removeFromFavorites(hymnId);
  }

  @override
  Future<bool> isFavorite(String hymnId) async {
    return _favoritesService.isFavorite(hymnId);
  }

  void refreshFavorites() {
    _favoritesService.refreshFavorites();
  }

  @override
  Future<Hymn?> getRandomHymn() async {
    final allHymns = await getAllHymns();
    if (allHymns.isEmpty) return null;
    final random = DateTime.now().millisecondsSinceEpoch % allHymns.length;
    return allHymns[random];
  }

  @override
  Future<List<Hymn>> getHymnsByNumberRange(int start, int end) async {
    final allHymns = await getAllHymns();
    return allHymns.where((hymn) {
      final hymnNumber = int.tryParse(hymn.hymnNumber) ?? 0;
      return hymnNumber >= start && hymnNumber <= end;
    }).toList();
  }

  @override
  Future<int> get hymnCount async => (await getAllHymns()).length;

  @override
  Future<List<String>> getCategories() async {
    final allHymns = await getAllHymns();
    final categories = <String>{};
    for (final hymn in allHymns) {
      if (hymn.title.isNotEmpty) {
        categories.add('General');
      }
    }
    final sortedCategories = categories.toList();
    sortedCategories.sort();
    return sortedCategories;
  }

  @override
  Future<List<String>> getAuthors() async {
    final allHymns = await getAllHymns();
    final authors = <String>{};
    for (final hymn in allHymns) {
      if (hymn.createdBy.isNotEmpty) {
        authors.add(hymn.createdBy);
      }
    }
    final sortedAuthors = authors.toList();
    sortedAuthors.sort();
    return sortedAuthors;
  }

  @override
  Future<void> initialize() async {
    await _combinedHymnService.initialize();
  }

  @override
  Future<void> refresh() async {
    // Refresh implemented by clearing cache and reloading
    clearCache();
    await initialize();
  }

  @override
  void clearCache() {
    _combinedHymnService.clearCache();
  }

  @override
  Future<Map<String, dynamic>> exportData() async {
    final allHymns = await getAllHymns();
    return {
      'hymns': allHymns.map((hymn) => hymn.toMap()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
  }

  @override
  Future<void> importData(Map<String, dynamic> data) async {
    try {
      // Validate data structure
      if (!data.containsKey('hymns') || data['hymns'] is! List) {
        throw Exception(
            'Invalid import data format: missing or invalid hymns array');
      }

      final hymnsData = data['hymns'] as List;
      final List<Hymn> importedHymns = [];

      // Convert each hymn data back to Hymn objects
      for (final hymnData in hymnsData) {
        if (hymnData is Map<String, dynamic>) {
          try {
            // Generate a unique ID for the imported hymn
            final id =
                'imported_${DateTime.now().millisecondsSinceEpoch}_${importedHymns.length}';
            final hymn = Hymn.fromJson(hymnData, id);
            importedHymns.add(hymn);
          } catch (e) {
            // Skip invalid hymn data but continue with others
            if (kDebugMode) {
              print('Warning: Failed to parse hymn data: $e');
            }
            continue;
          }
        }
      }

      if (importedHymns.isEmpty) {
        throw Exception('No valid hymns found in import data');
      }

      // Save imported hymns to local storage
      await _localStorageService.saveHymns(importedHymns);

      // Also save to Firebase if user is authenticated
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final firestore = FirebaseFirestore.instance;
          final batch = firestore.batch();

          for (final hymn in importedHymns) {
            final docRef = firestore.collection('hymns').doc(hymn.id);
            batch.set(docRef, hymn.toMap());
          }

          await batch.commit();
        }
      } catch (e) {
        // Firebase import is optional, don't fail the whole operation
        if (kDebugMode) {
          print('Warning: Failed to import to Firebase: $e');
        }
      }

      if (kDebugMode) {
        print('Successfully imported ${importedHymns.length} hymns');
      }
    } catch (e) {
      throw Exception('Failed to import hymns: $e');
    }
  }
}
