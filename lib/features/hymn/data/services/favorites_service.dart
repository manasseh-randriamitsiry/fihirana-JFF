import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/core/utils/firebase_sync_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FavoritesService {
  final FirebaseSyncService firebaseSyncService;
  final FirebaseAuth auth;
  final Future<List<Hymn>> Function() getAllHymns;
  final Future<Hymn?> Function(String) getHymnById;

  // Local cache and stream controllers
  final _favoriteStatusController = StreamController<Map<String, String>>.broadcast();
  final _favoriteIdsController = StreamController<List<String>>.broadcast();
  final _favoriteHymnsController = StreamController<List<Hymn>>.broadcast();
  
  Set<String> _cachedFavorites = {};
  bool _isInitialized = false;
  StreamSubscription? _firestoreSubscription;

  static const String _localFavoritesKey = 'local_favorites';

  FavoritesService({
    required this.firebaseSyncService,
    required this.auth,
    required this.getAllHymns,
    required this.getHymnById,
  }) {
    _initialize();
  }

  /// Initialize the favorites service
  Future<void> _initialize() async {
    if (_isInitialized) return;
    
    try {
      // Load local favorites first
      await _loadLocalFavorites();
      
      // Listen to auth changes
      auth.authStateChanges().listen((user) {
        if (user != null) {
          _loadFirebaseFavorites();
        } else {
          _cachedFavorites.clear();
          _updateStreams();
        }
      });
      
      // If user is already authenticated, load Firebase favorites
      if (auth.currentUser != null) {
        await _loadFirebaseFavorites();
      }
      
      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing FavoritesService: $e');
      }
    }
  }

  /// Load favorites from local storage
  Future<void> _loadLocalFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localFavoritesJson = prefs.getString(_localFavoritesKey);
      
      if (localFavoritesJson != null) {
        final List<dynamic> localFavorites = json.decode(localFavoritesJson);
        _cachedFavorites = localFavorites.whereType<String>().toSet();
        if (kDebugMode) {
          print('📚 Loaded ${_cachedFavorites.length} favorites from local storage');
        }
        _updateStreams();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading local favorites: $e');
      }
    }
  }

  /// Load favorites from Firebase and set up real-time listener
  Future<void> _loadFirebaseFavorites() async {
    final user = auth.currentUser;
    if (user == null) return;

    try {
      // Cancel existing subscription
      await _firestoreSubscription?.cancel();
      
      // Set up real-time listener
      _firestoreSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .snapshots()
          .listen((snapshot) {
        final firebaseFavorites = snapshot.docs
            .map((doc) => doc.data()['hymnId'] as String?)
            .whereType<String>()
            .toSet();
        
        _cachedFavorites = firebaseFavorites;
        if (kDebugMode) {
          print('🎵 Loaded ${_cachedFavorites.length} favorites from Firebase');
        }
        
        // Update local storage
        _saveLocalFavorites();
        
        // Update streams
        _updateStreams();
      }, onError: (error) {
        if (kDebugMode) {
          print('❌ Error streaming Firebase favorites: $error');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading Firebase favorites: $e');
      }
    }
  }

  /// Save favorites to local storage
  Future<void> _saveLocalFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesList = _cachedFavorites.toList();
      await prefs.setString(_localFavoritesKey, json.encode(favoritesList));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving local favorites: $e');
      }
    }
  }

  /// Update all stream controllers
  void _updateStreams() {
    // Update favorite status stream (Map format)
    final statusMap = <String, String>{};
    for (final hymnId in _cachedFavorites) {
      statusMap[hymnId] = 'favorite';
    }
    _favoriteStatusController.add(statusMap);
    
    // Update favorite IDs stream
    _favoriteIdsController.add(_cachedFavorites.toList());
    
    // Update favorite hymns stream (load actual hymn objects)
    _loadAndStreamFavoriteHymns();
  }

  /// Load hymn objects for all favorite IDs and stream them
  Future<void> _loadAndStreamFavoriteHymns() async {
    try {
      final hymns = <Hymn>[];
      
      for (final hymnId in _cachedFavorites) {
        final hymn = await getHymnById(hymnId);
        if (hymn != null) {
          hymns.add(hymn);
        }
      }
      
      _favoriteHymnsController.add(hymns);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading favorite hymns: $e');
      }
    }
  }

  /// Stream of favorite status (Map<hymnId, 'favorite'>)
  Stream<Map<String, String>> getFavoriteStatusStream() {
    return _favoriteStatusController.stream;
  }

  /// Stream of favorite hymn IDs
  Stream<List<String>> getFavoriteHymnIdsStream() {
    return _favoriteIdsController.stream;
  }

  /// Stream of favorite hymns
  Stream<List<Hymn>> getFavoriteHymnsStream() {
    return _favoriteHymnsController.stream;
  }

  /// Get favorite hymns (one-time fetch)
  Future<List<Hymn>> getFavoriteHymns() async {
    final hymns = <Hymn>[];
    
    for (final hymnId in _cachedFavorites) {
      final hymn = await getHymnById(hymnId);
      if (hymn != null) {
        hymns.add(hymn);
      }
    }
    
    return hymns;
  }

  /// Toggle favorite status for a hymn
  Future<void> toggleFavorite(Hymn hymn) async {
    try {
      final isFavorite = _cachedFavorites.contains(hymn.id);
      
      if (isFavorite) {
        await removeFromFavorites(hymn.id);
        if (kDebugMode) {
          print('💔 Removed ${hymn.title} from favorites');
        }
      } else {
        await addToFavorites(hymn.id);
        if (kDebugMode) {
          print('❤️ Added ${hymn.title} to favorites');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error toggling favorite: $e');
      }
      rethrow;
    }
  }

  /// Add hymn to favorites
  Future<void> addToFavorites(String hymnId) async {
    try {
      // Add to cache
      _cachedFavorites.add(hymnId);
      
      // Update local storage
      await _saveLocalFavorites();
      
      // Update Firebase if user is authenticated
      final user = auth.currentUser;
      if (user != null) {
        await firebaseSyncService.addFavoriteToFirebase(hymnId);
      }
      
      // Update streams
      _updateStreams();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error adding to favorites: $e');
      }
      rethrow;
    }
  }

  /// Remove hymn from favorites
  Future<void> removeFromFavorites(String hymnId) async {
    try {
      // Remove from cache
      _cachedFavorites.remove(hymnId);
      
      // Update local storage
      await _saveLocalFavorites();
      
      // Update Firebase if user is authenticated
      final user = auth.currentUser;
      if (user != null) {
        await firebaseSyncService.removeFavoriteFromFirebase(hymnId);
      }
      
      // Update streams
      _updateStreams();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error removing from favorites: $e');
      }
      rethrow;
    }
  }

  /// Check if a hymn is a favorite
  Future<bool> isFavorite(String hymnId) async {
    return _cachedFavorites.contains(hymnId);
  }

  /// Check if hymn is favorite (alias for backward compatibility)
  Future<bool> isHymnFavorite(String hymnId) async {
    return await isFavorite(hymnId);
  }

  /// Dispose of the service
  void dispose() {
    _firestoreSubscription?.cancel();
    _favoriteStatusController.close();
    _favoriteIdsController.close();
    _favoriteHymnsController.close();
  }
}