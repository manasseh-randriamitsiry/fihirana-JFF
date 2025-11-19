import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import '../models/hymn.dart';

class CombinedHymnService {
  static final CombinedHymnService _instance = CombinedHymnService._internal();
  factory CombinedHymnService() => _instance;
  CombinedHymnService._internal();

  final Map<String, Hymn> _hymnCache = {};
  List<Hymn>? _allHymns;
  bool _isInitialized = false;
  bool _isInitializing = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_isInitializing) return;

    _isInitializing = true;
    
    try {
      await _loadCombinedHymns();
      _isInitialized = true;
      if (kDebugMode) {
        print('CombinedHymnService initialized with ${_allHymns?.length ?? 0} hymns');
      }
    } catch (e) {
      if (kDebugMode) {
        print('CombinedHymnService initialization failed: $e');
      }
      // Fallback to individual file loading
      await _loadIndividualHymns();
      _isInitialized = true;
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _loadCombinedHymns() async {
    try {
      if (kDebugMode) {
        print('Loading combined hymn file...');
      }
      
      final jsonString = await rootBundle.loadString('assets/hymns_combined.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      
      if (!jsonData.containsKey('hymns')) {
        throw Exception('Invalid hymns_combined.json format: missing "hymns" key');
      }

      final hymnsData = jsonData['hymns'] as List<dynamic>;
      final List<Hymn> hymns = [];
      
      for (final hymnData in hymnsData) {
        try {
          final hymnMap = hymnData as Map<String, dynamic>;
          final hymn = _parseHymnFromJson(hymnMap, hymnMap['number'].toString());
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
        if (hymns.isNotEmpty) {
          print('First hymn: ${hymns.first.title} (${hymns.first.hymnNumber})');
          print('Last hymn: ${hymns.last.title} (${hymns.last.hymnNumber})');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load combined hymn file: $e');
      }
      rethrow;
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
    return _allHymns ?? [];
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
      }
      return hymn;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load hymn $id: $e');
      }
      return null;
    }
  }

  Future<List<Hymn>> searchHymns(String query) async {
    final allHymns = await getAllHymns();
    if (query.isEmpty) return allHymns;

    final lowerQuery = query.toLowerCase();
    return allHymns.where((hymn) {
      return hymn.hymnNumber.toLowerCase().contains(lowerQuery) ||
          hymn.title.toLowerCase().contains(lowerQuery);
    }).toList();
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

  void clearCache() {
    _hymnCache.clear();
    _allHymns = null;
    _isInitialized = false;
    _isInitializing = false;
  }

  bool get isInitialized => _isInitialized;
}