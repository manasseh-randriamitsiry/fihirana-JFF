import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import '../models/hymn.dart';

class LocalHymnService {
  static final LocalHymnService _instance = LocalHymnService._internal();
  factory LocalHymnService() => _instance;
  LocalHymnService._internal();

  final Map<String, Hymn> _hymnCache = {};
  List<Hymn>? _allHymns;

  Future<List<Hymn>> getAllHymns() async {
    if (_allHymns != null) {
      return _allHymns!;
    }

    try {
      // Try to load from manifest first (debug mode)
      try {
        final manifestContent =
            await rootBundle.loadString('AssetManifest.json');
        final Map<String, dynamic> manifestMap = json.decode(manifestContent);

        final List<Hymn> hymns = [];

        final jsonAssets = manifestMap.keys
            .where((key) =>
                key.startsWith('assets/json/') && key.endsWith('.json'))
            .toList();

        // Process assets in smaller batches to avoid memory issues
        const batchSize = 20;
        for (var i = 0; i < jsonAssets.length; i += batchSize) {
          final end = (i + batchSize < jsonAssets.length)
              ? i + batchSize
              : jsonAssets.length;
          final batch = jsonAssets.sublist(i, end);

          for (final assetPath in batch) {
            try {
              final jsonString = await rootBundle.loadString(assetPath);
              final jsonData = json.decode(jsonString);

              final hymn =
                  _parseHymnFromJson(jsonData, _extractIdFromPath(assetPath));
              hymns.add(hymn);
              _hymnCache[hymn.id] = hymn;
            } catch (e) {
              if (kDebugMode) {
                print('Error loading hymn from $assetPath: $e');
              }
            }
          }

          // Add a small delay to prevent blocking the UI
          await Future.delayed(const Duration(milliseconds: 10));
        }

        hymns.sort((a, b) {
          final numA = int.tryParse(a.hymnNumber) ?? 0;
          final numB = int.tryParse(b.hymnNumber) ?? 0;
          return numA.compareTo(numB);
        });

        _allHymns = hymns;
        return hymns;
      } catch (manifestError) {
        // If manifest loading fails, try fallback method for release mode
        if (kDebugMode) {
          print(
              'AssetManifest loading failed, trying fallback method: $manifestError');
        }
        return await _loadHymnsFallback();
      }
    } catch (e) {
      // Final fallback
      if (kDebugMode) {
        print('getAllHymns failed: $e');
      }
      return await _loadHymnsFallback();
    }
  }

  Future<List<Hymn>> _loadHymnsFallback() async {
    final List<Hymn> hymns = [];

    // Try to load a few sample hymns to check if the system works
    try {
      // This is a fallback approach - in a real app, you might want to
      // have a predefined list of hymn IDs or use a different approach
      for (int i = 1; i <= 1000; i++) {
        try {
          final assetPath = 'assets/json/$i.json';
          final jsonString = await rootBundle.loadString(assetPath);
          final jsonData = json.decode(jsonString);

          final hymn = _parseHymnFromJson(jsonData, i.toString());
          hymns.add(hymn);
          _hymnCache[hymn.id] = hymn;
        } catch (e) {
          // Continue with next hymn
          continue;
        }
      }

      if (hymns.isNotEmpty) {
        hymns.sort((a, b) {
          final numA = int.tryParse(a.hymnNumber) ?? 0;
          final numB = int.tryParse(b.hymnNumber) ?? 0;
          return numA.compareTo(numB);
        });

        _allHymns = hymns;
        return hymns;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Fallback loading failed: $e');
      }
    }

    return [];
  }

  Future<Hymn?> getHymnById(String id) async {
    if (_hymnCache.containsKey(id)) {
      return _hymnCache[id];
    }

    try {
      final assetPath = 'assets/json/$id.json';
      final jsonString = await rootBundle.loadString(assetPath);
      final jsonData = json.decode(jsonString);

      final hymn = _parseHymnFromJson(jsonData, id);
      _hymnCache[id] = hymn;
      return hymn;
    } catch (e) {
      // Try fallback approach
      try {
        // In release mode, try to load with different path patterns
        final fallbackPaths = [
          'assets/json/$id.json',
          'assets/json/${id.padLeft(3, '0')}.json',
          'assets/json/hymn_$id.json',
        ];

        for (final path in fallbackPaths) {
          try {
            final jsonString = await rootBundle.loadString(path);
            final jsonData = json.decode(jsonString);
            final hymn = _parseHymnFromJson(jsonData, id);
            _hymnCache[id] = hymn;
            return hymn;
          } catch (pathError) {
            continue;
          }
        }
      } catch (fallbackError) {
        if (kDebugMode) {
          print('getHymnById failed for id $id: $e');
        }
      }
      return null;
    }
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

  String _extractIdFromPath(String path) {
    final fileName = path.split('/').last;
    return fileName.substring(0, fileName.lastIndexOf('.'));
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

  void clearCache() {
    _hymnCache.clear();
    _allHymns = null;
  }
}
