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
      // First try to load our custom hymn manifest
      try {
        if (kDebugMode) {
          print('Attempting to load custom hymn manifest...');
        }
        final manifestContent = await rootBundle.loadString('assets/hymn_manifest.json');
        final Map<String, dynamic> hymnManifest = json.decode(manifestContent);
        
        if (hymnManifest.isNotEmpty) {
          return await _loadFromCustomManifest(hymnManifest);
        }
      } catch (e) {
        if (kDebugMode) {
          print('Custom hymn manifest not found, trying AssetManifest.json...');
        }
      }

      // Try to load from AssetManifest.json
      try {
        if (kDebugMode) {
          print('Attempting to load AssetManifest.json...');
        }
        final manifestContent =
            await rootBundle.loadString('AssetManifest.json');
        final Map<String, dynamic> manifestMap = json.decode(manifestContent);

        final List<Hymn> hymns = [];

        final jsonAssets = manifestMap.keys
            .where((key) =>
                key.startsWith('assets/json/') && key.endsWith('.json'))
            .toList();

        if (kDebugMode) {
          print('Found ${jsonAssets.length} JSON assets in manifest');
          print('Total manifest keys: ${manifestMap.keys.length}');
          if (jsonAssets.isNotEmpty) {
            print('First few assets: ${jsonAssets.take(5).join(', ')}');
          } else {
            print('No JSON assets found! Available asset types:');
            final assetTypes = manifestMap.keys.map((k) => k.split('.').last).toSet();
            print('Asset extensions: ${assetTypes.take(10).join(', ')}');
            print('Sample keys: ${manifestMap.keys.take(20).toList()}');
          }
        }

        if (jsonAssets.isEmpty) {
          if (kDebugMode) {
            print('No JSON assets found in manifest, trying fallback method');
          }
          return await _loadHymnsFallback();
        }

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

  Future<List<Hymn>> _loadFromCustomManifest(Map<String, dynamic> hymnManifest) async {
    final List<Hymn> hymns = [];
    
    if (kDebugMode) {
      print('Loading ${hymnManifest.length} hymns from custom manifest');
    }

    try {
      int successCount = 0;
      int failureCount = 0;
      
      for (final entry in hymnManifest.entries) {
        try {
          final hymnId = entry.key;
          final assetPath = entry.value.toString();
          
          final jsonString = await rootBundle.loadString(assetPath);
          final jsonData = json.decode(jsonString);
          final hymn = _parseHymnFromJson(jsonData, hymnId);
          
          hymns.add(hymn);
          _hymnCache[hymn.id] = hymn;
          successCount++;
          
          if (kDebugMode && successCount <= 5) {
            print('Loaded hymn $hymnId from $assetPath: ${hymn.title}');
          }
        } catch (e) {
          failureCount++;
          if (kDebugMode && failureCount <= 5) {
            print('Failed to load hymn ${entry.key}: $e');
          }
        }
        
        // Add a small delay every 50 hymns to prevent overwhelming the system
        if (hymns.length % 50 == 0) {
          await Future.delayed(const Duration(milliseconds: 5));
        }
      }
      
      if (hymns.isNotEmpty) {
        hymns.sort((a, b) {
          final numA = int.tryParse(a.hymnNumber) ?? 0;
          final numB = int.tryParse(b.hymnNumber) ?? 0;
          return numA.compareTo(numB);
        });

        _allHymns = hymns;
        
        if (kDebugMode) {
          print('Successfully loaded ${hymns.length} hymns from custom manifest');
          print('Success rate: $successCount loaded, $failureCount failed');
          print('First hymn: ${hymns.first.title} (${hymns.first.hymnNumber})');
          print('Last hymn: ${hymns.last.title} (${hymns.last.hymnNumber})');
        }
        
        return hymns;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Custom manifest loading failed: $e');
      }
    }
    
    return [];
  }

  Future<List<Hymn>> _loadHymnsFallback() async {
    final List<Hymn> hymns = [];

    if (kDebugMode) {
      print('Starting fallback hymn loading method...');
    }

    try {
      // Try a range of hymn IDs based on the actual file count
      // We know there are 829 JSON files from our check
      int successCount = 0;
      int failureCount = 0;
      
      for (int i = 1; i <= 1000; i++) {
        try {
          // Try different naming patterns
          final possiblePaths = [
            'assets/json/$i.json',
            'assets/json/${i.toString().padLeft(3, '0')}.json',
          ];

          Hymn? hymn;
          String? successfulPath;
          
          for (final path in possiblePaths) {
            try {
              final jsonString = await rootBundle.loadString(path);
              final jsonData = json.decode(jsonString);
              hymn = _parseHymnFromJson(jsonData, i.toString());
              successfulPath = path;
              break;
            } catch (pathError) {
              continue;
            }
          }

          if (hymn != null) {
            hymns.add(hymn);
            _hymnCache[hymn.id] = hymn;
            successCount++;
            
            if (kDebugMode && successCount <= 5) {
              print('Loaded hymn $i from $successfulPath: ${hymn.title}');
            }
          } else {
            failureCount++;
          }
        } catch (e) {
          failureCount++;
          // Continue with next hymn
          continue;
        }

        // Add a small delay every 50 hymns to prevent overwhelming the system
        if (i % 50 == 0) {
          await Future.delayed(const Duration(milliseconds: 5));
          if (kDebugMode) {
            print('Progress: $i hymns checked, $successCount loaded, $failureCount failed');
          }
        }
      }

      if (hymns.isNotEmpty) {
        if (kDebugMode) {
          print('Successfully loaded ${hymns.length} hymns using fallback method');
          print('Success rate: $successCount loaded, $failureCount failed');
          print('First hymn: ${hymns.first.title} (${hymns.first.hymnNumber})');
          print('Last hymn: ${hymns.last.title} (${hymns.last.hymnNumber})');
        }
        
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
