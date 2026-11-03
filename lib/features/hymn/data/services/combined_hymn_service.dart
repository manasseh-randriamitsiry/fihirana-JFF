import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'local_hymn_service.dart';

class CombinedHymnService {
  static final CombinedHymnService _instance = CombinedHymnService._internal();
  factory CombinedHymnService() => _instance;
  CombinedHymnService._internal();

  final Map<String, Hymn> _hymnCache = {};
  List<Hymn>? _allHymns;
  bool _isInitialized = false;
  Future<void>? _initialization;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() {
    if (_isInitialized) return Future.value();
    // Concurrent callers must await the same load: returning early while a load
    // is in flight handed them an empty corpus.
    return _initialization ??= _loadCorpus();
  }

  Future<void> _loadCorpus() async {
    try {
      await _loadCombinedHymns();
      // Optimization: Don't load all Firebase hymns at startup
      // await _loadFirebaseHymns();
      _isInitialized = true;
      if (kDebugMode) {
        print(
            'CombinedHymnService initialized with ${_allHymns?.length ?? 0} hymns');
      }
    } catch (e) {
      if (kDebugMode) {
        print('CombinedHymnService initialization failed: $e');
      }
      // Fallback to individual file loading
      await _loadIndividualHymns();
      _isInitialized = true;
    } finally {
      // A load that did not finish must not be cached for later callers.
      if (!_isInitialized) _initialization = null;
    }
  }

  Future<void> _loadCombinedHymns() async {
    try {
      if (kDebugMode) {
        print('Loading combined hymn file...');
      }

      final jsonString =
          await rootBundle.loadString('assets/hymns_combined.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      if (!jsonData.containsKey('hymns')) {
        throw Exception(
            'Invalid hymns_combined.json format: missing "hymns" key');
      }

      final hymnsData = jsonData['hymns'] as List<dynamic>;
      final List<Hymn> hymns = [];

      for (final hymnData in hymnsData) {
        try {
          final hymnMap = hymnData as Map<String, dynamic>;
          // Use filename as ID (without .json extension) for audio compatibility
          final fileName =
              hymnMap['file_path'] as String? ?? '${hymnMap['number']}.json';
          final hymnId = fileName.replaceAll('.json', '');
          final hymn = _parseHymnFromJson(hymnMap, hymnId);
          hymns.add(hymn);
          _hymnCache[hymn.id] = hymn;
        } catch (e) {
          if (kDebugMode) {
            print('Failed to parse hymn: $e');
          }
        }
      }

      // Sort by hymn number
      hymns.sort((a, b) {
        final numA = int.tryParse(a.hymnNumber) ?? 0;
        final numB = int.tryParse(b.hymnNumber) ?? 0;
        return numA.compareTo(numB);
      });

      _allHymns = hymns;

      if (kDebugMode) {
        print('Successfully loaded ${hymns.length} hymns from combined file');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load combined hymn file: $e');
      }
      rethrow;
    }
  }

  /// Load hymns from Firebase that are not already in the local list
  Future<void> loadMoreFromFirebase() async {
    await _loadFirebaseHymns();
  }

  Future<void> _loadFirebaseHymns() async {
    try {
      if (kDebugMode) {
        print('Loading Firebase hymns...');
      }

      final snapshot = await _firestore.collection('hymns').get();
      final firebaseHymns = snapshot.docs.map((doc) {
        final data = doc.data();
        return Hymn.fromJson(data, doc.id);
      }).toList();

      if (_allHymns == null) {
        _allHymns = firebaseHymns;
      } else {
        // Combine with existing hymns, avoiding duplicates
        final existingIds = _allHymns!.map((h) => h.id).toSet();
        final newHymns =
            firebaseHymns.where((h) => !existingIds.contains(h.id)).toList();
        _allHymns!.addAll(newHymns);
      }

      // Add to cache
      for (final hymn in firebaseHymns) {
        _hymnCache[hymn.id] = hymn;
      }

      // Sort all hymns by number
      _allHymns!.sort((a, b) {
        final numA = int.tryParse(a.hymnNumber) ?? 0;
        final numB = int.tryParse(b.hymnNumber) ?? 0;
        return numA.compareTo(numB);
      });

      if (kDebugMode) {
        print('Successfully loaded ${firebaseHymns.length} Firebase hymns');
        print('Total hymns after combining: ${_allHymns!.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load Firebase hymns: $e');
      }
      // Don't rethrow - Firebase hymns are optional
    }
  }

  Future<void> _loadIndividualHymns() async {
    if (kDebugMode) {
      print('Falling back to individual hymn file loading...');
    }

    // Use the existing LocalHymnService as fallback
    final localService = LocalHymnService();
    _allHymns = await localService.getAllHymns();

    for (final hymn in _allHymns!) {
      _hymnCache[hymn.id] = hymn;
    }
  }

  Future<List<Hymn>> getAllHymns() async {
    if (!_isInitialized) {
      await initialize();
    }
    // Hand out a copy: callers sort and filter the result in place, which would
    // otherwise rewrite the shared corpus for every other reader.
    final hymns = _allHymns;
    return hymns == null ? [] : List<Hymn>.from(hymns);
  }

  Future<Hymn?> getHymnById(String id) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_hymnCache.containsKey(id)) {
      return _hymnCache[id];
    }

    // Try to load individual hymn if not in cache
    try {
      final localService = LocalHymnService();
      final hymn = await localService.getHymnById(id);
      if (hymn != null) {
        _hymnCache[id] = hymn;
        return hymn;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load local hymn $id: $e');
      }
    }

    // Try Firebase if not found locally
    try {
      final doc = await _firestore.collection('hymns').doc(id).get();
      if (doc.exists) {
        final hymn = Hymn.fromJson(doc.data()!, doc.id);
        _hymnCache[id] = hymn;
        // Add to the all hymns list if it exists
        if (_allHymns != null) {
          final existingIds = _allHymns!.map((h) => h.id).toSet();
          if (!existingIds.contains(hymn.id)) {
            _allHymns!.add(hymn);
            // Re-sort
            _allHymns!.sort((a, b) {
              final numA = int.tryParse(a.hymnNumber) ?? 0;
              final numB = int.tryParse(b.hymnNumber) ?? 0;
              return numA.compareTo(numB);
            });
          }
        }
        return hymn;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load Firebase hymn $id: $e');
      }
    }

    return null;
  }

  Future<List<Hymn>> searchHymns(String query) async {
    final allHymns = await getAllHymns();
    if (query.isEmpty) return allHymns;

    final lowerQuery = query.toLowerCase();
    final results = allHymns.where((hymn) {
      final numberMatch = hymn.hymnNumber.toLowerCase().contains(lowerQuery);
      final titleMatch = hymn.title.toLowerCase().contains(lowerQuery);
      final chorusMatch =
          hymn.bridge?.toLowerCase().contains(lowerQuery) ?? false;
      final verseMatch =
          hymn.verses.any((v) => v.toLowerCase().contains(lowerQuery));

      return numberMatch || titleMatch || chorusMatch || verseMatch;
    }).toList();

    // Sort results by relevance
    results.sort((a, b) {
      // 1. Exact number match
      if (a.hymnNumber == query && b.hymnNumber != query) return -1;
      if (b.hymnNumber == query && a.hymnNumber != query) return 1;

      // 2. Starts with number
      final aNumStart = a.hymnNumber.startsWith(query);
      final bNumStart = b.hymnNumber.startsWith(query);
      if (aNumStart && !bNumStart) return -1;
      if (!aNumStart && bNumStart) return 1;

      // 3. Title match
      final aTitle = a.title.toLowerCase().contains(lowerQuery);
      final bTitle = b.title.toLowerCase().contains(lowerQuery);
      if (aTitle && !bTitle) return -1;
      if (!aTitle && bTitle) return 1;

      // 4. Numeric sort for remainder
      final numA = int.tryParse(a.hymnNumber) ?? 0;
      final numB = int.tryParse(b.hymnNumber) ?? 0;
      return numA.compareTo(numB);
    });

    return results;
  }

  Hymn _parseHymnFromJson(Map<String, dynamic> jsonData, String id) {
    final List<String> verses = [];
    if (jsonData['verses'] is Map<String, dynamic>) {
      final versesMap = jsonData['verses'] as Map<String, dynamic>;

      final sortedKeys = versesMap.keys.toList()
        ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

      for (final key in sortedKeys) {
        verses.add(versesMap[key].toString());
      }
    } else if (jsonData['verses'] is List) {
      verses.addAll(List<String>.from(jsonData['verses']));
    }

    // Extract bridge/chorus
    String? bridge = jsonData['bridge']?.toString();
    if (bridge == null && jsonData['chorus'] != null) {
      bridge = jsonData['chorus'].toString();
    }

    return Hymn(
      id: id,
      hymnNumber: jsonData['number'].toString(),
      title: jsonData['title'].toString(),
      verses: verses,
      bridge: bridge,
      hymnHint: jsonData['hint']?.toString(),
      createdAt: DateTime.now(),
      createdBy: 'Local File',
    );
  }

  Future<void> clearCache() async {
    // Await the in-flight load before wiping: dropping the handle would let it
    // repopulate the cache we just cleared.
    await _initialization?.catchError((_) {});
    _initialization = null;
    _hymnCache.clear();
    _allHymns = null;
    _isInitialized = false;
  }

  bool get isInitialized => _isInitialized;
}
