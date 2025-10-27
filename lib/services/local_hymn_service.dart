import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import '../models/hymn.dart';

class LocalHymnService {
  static final LocalHymnService _instance = LocalHymnService._internal();
  factory LocalHymnService() => _instance;
  LocalHymnService._internal();

  // Cache for loaded hymns
  final Map<String, Hymn> _hymnCache = {};
  List<Hymn>? _allHymns;

  /// Load all hymns from local JSON files
  Future<List<Hymn>> getAllHymns() async {
    if (_allHymns != null) {
      return _allHymns!;
    }

    try {
      // Load the list of JSON files
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      final List<Hymn> hymns = [];
      
      // Filter for JSON files in the assets/json directory
      final jsonAssets = manifestMap.keys
          .where((key) => key.startsWith('assets/json/') && key.endsWith('.json'))
          .toList();

      // Load each hymn file
      for (final assetPath in jsonAssets) {
        try {
          final jsonString = await rootBundle.loadString(assetPath);
          final jsonData = json.decode(jsonString);
          
          final hymn = _parseHymnFromJson(jsonData, _extractIdFromPath(assetPath));
          hymns.add(hymn);
          _hymnCache[hymn.id] = hymn;
        } catch (e) {
          print('Error loading hymn from $assetPath: $e');
        }
      }

      // Sort hymns by number
      hymns.sort((a, b) {
        final numA = int.tryParse(a.hymnNumber) ?? 0;
        final numB = int.tryParse(b.hymnNumber) ?? 0;
        return numA.compareTo(numB);
      });

      _allHymns = hymns;
      return hymns;
    } catch (e) {
      print('Error loading all hymns: $e');
      return [];
    }
  }

  /// Get a specific hymn by ID
  Future<Hymn?> getHymnById(String id) async {
    // Check cache first
    if (_hymnCache.containsKey(id)) {
      return _hymnCache[id];
    }

    try {
      // Try to load from assets
      final assetPath = 'assets/json/$id.json';
      final jsonString = await rootBundle.loadString(assetPath);
      final jsonData = json.decode(jsonString);
      
      final hymn = _parseHymnFromJson(jsonData, id);
      _hymnCache[id] = hymn;
      return hymn;
    } catch (e) {
      print('Error loading hymn $id: $e');
      return null;
    }
  }

  /// Parse hymn data from JSON structure
  Hymn _parseHymnFromJson(Map<String, dynamic> jsonData, String id) {
    // Extract verses from the JSON structure
    final List<String> verses = [];
    if (jsonData['verses'] is Map<String, dynamic>) {
      final versesMap = jsonData['verses'] as Map<String, dynamic>;
      // Sort verse keys numerically
      final sortedKeys = versesMap.keys.toList()
        ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
      
      for (final key in sortedKeys) {
        verses.add(versesMap[key].toString());
      }
    } else if (jsonData['verses'] is List) {
      verses.addAll(List<String>.from(jsonData['verses']));
    }

    // Extract chorus if it exists and add it as the last verse
    if (jsonData['chorus'] != null) {
      verses.add(jsonData['chorus'].toString());
    }

    return Hymn(
      id: id,
      hymnNumber: jsonData['number'].toString(),
      title: jsonData['title'].toString(),
      verses: verses,
      bridge: jsonData['bridge']?.toString(),
      hymnHint: jsonData['hint']?.toString(),
      createdAt: DateTime.now(),
      createdBy: 'Local File',
    );
  }

  /// Extract ID from file path (e.g., "assets/json/123-Title.json" -> "123-Title")
  String _extractIdFromPath(String path) {
    final fileName = path.split('/').last;
    return fileName.substring(0, fileName.lastIndexOf('.'));
  }

  /// Search hymns by number or title
  Future<List<Hymn>> searchHymns(String query) async {
    final allHymns = await getAllHymns();
    if (query.isEmpty) return allHymns;

    final lowerQuery = query.toLowerCase();
    return allHymns.where((hymn) {
      return hymn.hymnNumber.toLowerCase().contains(lowerQuery) ||
             hymn.title.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Clear cache
  void clearCache() {
    _hymnCache.clear();
    _allHymns = null;
  }
}