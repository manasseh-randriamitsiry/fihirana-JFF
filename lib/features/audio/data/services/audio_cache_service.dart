import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'audio_file_mapping.dart';

class AudioCacheService {
  static final AudioCacheService _instance = AudioCacheService._internal();
  factory AudioCacheService() => _instance;
  AudioCacheService._internal();

  Database? _database;
  final Map<String, bool> _memoryCache = {};
  final Set<String> _pendingChecks = {};
  static const String _tableName = 'audio_cache';
  static const Duration _cacheExpiry =
      Duration(minutes: 5); // Cache for 5 minutes for testing

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'audio_cache.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE $_tableName (
            hymn_id TEXT PRIMARY KEY,
            has_audio INTEGER NOT NULL,
            last_checked INTEGER NOT NULL,
            created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
          )
        ''');
      },
    );
  }

  /// Clear all cached audio data
  Future<void> clearCache() async {
    final db = await database;
    await db.delete(_tableName);
    _memoryCache.clear();
    if (kDebugMode) {
      print('AudioCache: Cache cleared');
    }
  }

  /// Check if audio exists for a hymn (uses cache first)
  Future<bool> checkAudioExists(String hymnId) async {
    // Check memory cache first
    if (_memoryCache.containsKey(hymnId)) {
      if (kDebugMode) {
        print(
            'AudioCache: Found $hymnId in memory cache: ${_memoryCache[hymnId]}');
      }
      return _memoryCache[hymnId]!;
    }

    // Check if we're already checking this hymn
    if (_pendingChecks.contains(hymnId)) {
      if (kDebugMode) {
        print('AudioCache: Already checking $hymnId, waiting...');
      }

      // Wait for the check to complete
      while (_pendingChecks.contains(hymnId)) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      return _memoryCache[hymnId] ?? false;
    }

    _pendingChecks.add(hymnId);

    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'hymn_id = ?',
        whereArgs: [hymnId],
      );

      if (maps.isNotEmpty) {
        final lastChecked =
            DateTime.fromMillisecondsSinceEpoch(maps.first['last_checked']);
        final hasAudio = maps.first['has_audio'] == 1;

        // Check if cache is still valid
        if (DateTime.now().difference(lastChecked) < _cacheExpiry) {
          if (kDebugMode) {
            print('AudioCache: Found $hymnId in database cache: $hasAudio');
          }
          _memoryCache[hymnId] = hasAudio;
          return hasAudio;
        } else {
          if (kDebugMode) {
            print('AudioCache: Cache expired for $hymnId, refreshing...');
          }
          // Remove expired entry
          await db.delete(
            _tableName,
            where: 'hymn_id = ?',
            whereArgs: [hymnId],
          );
        }
      }

      // Cache miss or expired, check actual availability
      final hasAudio = await _checkActualAudioAvailability(hymnId);

      // Cache the result
      await _cacheAudioAvailability(hymnId, hasAudio);
      _memoryCache[hymnId] = hasAudio;

      if (kDebugMode) {
        print('AudioCache: Checked $hymnId from network: $hasAudio');
      }
      return hasAudio;
    } catch (e) {
      if (kDebugMode) {
        print('AudioCache: Error checking $hymnId: $e');
      }
      return false;
    } finally {
      _pendingChecks.remove(hymnId);
    }
  }

  /// Check multiple hymns at once (batch operation)
  Future<Map<String, bool>> checkMultipleAudioExists(
      List<String> hymnIds) async {
    final Map<String, bool> results = {};
    final List<String> uncachedIds = [];

    // First, check memory cache
    for (final hymnId in hymnIds) {
      if (_memoryCache.containsKey(hymnId)) {
        results[hymnId] = _memoryCache[hymnId]!;
      } else {
        uncachedIds.add(hymnId);
      }
    }

    if (uncachedIds.isEmpty) {
      if (kDebugMode) {
        print('AudioCache: All hymns found in memory cache');
      }
      return results;
    }

    // Check database cache for uncached hymns
    final db = await database;
    final placeholders = List.filled(uncachedIds.length, '?').join(',');
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT hymn_id, has_audio, last_checked FROM $_tableName WHERE hymn_id IN ($placeholders)',
      uncachedIds,
    );

    final Map<String, bool> dbResults = {};
    final List<String> stillUncachedIds = [];
    final DateTime now = DateTime.now();

    for (final map in maps) {
      final hymnId = map['hymn_id'] as String;
      final lastChecked =
          DateTime.fromMillisecondsSinceEpoch(map['last_checked']);
      final hasAudio = map['has_audio'] == 1;

      if (now.difference(lastChecked) < _cacheExpiry) {
        dbResults[hymnId] = hasAudio;
        _memoryCache[hymnId] = hasAudio;
      } else {
        stillUncachedIds.add(hymnId);
        // Remove expired entry
        await db.delete(
          _tableName,
          where: 'hymn_id = ?',
          whereArgs: [hymnId],
        );
      }
    }

    // Combine results
    results.addAll(dbResults);

    // Find hymns that need network check
    final List<String> networkCheckIds = [];
    for (final hymnId in uncachedIds) {
      if (!dbResults.containsKey(hymnId)) {
        networkCheckIds.add(hymnId);
      }
    }

    // Batch check network availability
    if (networkCheckIds.isNotEmpty) {
      if (kDebugMode) {
        print(
            'AudioCache: Checking ${networkCheckIds.length} hymns from network');
      }
      final networkResults =
          await _batchCheckNetworkAvailability(networkCheckIds);

      // Cache network results
      for (final entry in networkResults.entries) {
        await _cacheAudioAvailability(entry.key, entry.value);
        _memoryCache[entry.key] = entry.value;
        results[entry.key] = entry.value;
      }
    }

    return results;
  }

  /// Check actual audio availability from network
  Future<bool> _checkActualAudioAvailability(String hymnId) async {
    // For our hymns, the audio files are named exactly like the hymn IDs with .mp3 extension
    // So try the direct URL first
    final directUrl =
        'https://raw.githubusercontent.com/manasseh-randriamitsiry/Fihirana-audio/main/$hymnId.mp3';

    try {
      if (kDebugMode) {
        print('AudioCache: Checking direct URL for $hymnId: $directUrl');
      }

      final response = await http.head(
        Uri.parse(directUrl),
        headers: {
          'User-Agent': 'Fihirana-JFF-App/1.0',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('AudioCache: ✅ Found audio for $hymnId at direct URL');
        }
        return true;
      } else {
        if (kDebugMode) {
          print(
              'AudioCache: ❌ Direct URL returned ${response.statusCode} for $hymnId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('AudioCache: ❌ Direct URL check failed for $hymnId: $e');
      }
    }

    // Fallback: try the AudioFileMapping approach
    final audioMapping = AudioFileMapping();
    String? audioUrl = audioMapping.getAudioUrl(hymnId);

    if (audioUrl == null && audioMapping.isCacheExpired()) {
      try {
        if (kDebugMode) {
          print('AudioCache: Updating audio mapping for $hymnId');
        }
        await audioMapping.updateAudioFileMapping();
        audioUrl = audioMapping.getAudioUrl(hymnId);
      } catch (e) {
        if (kDebugMode) {
          print('AudioCache: Failed to update audio mapping: $e');
        }
      }
    }

    if (audioUrl != null) {
      try {
        if (kDebugMode) {
          print('AudioCache: Checking mapping URL for $hymnId: $audioUrl');
        }

        final response = await http.head(
          Uri.parse(audioUrl),
          headers: {
            'User-Agent': 'Fihirana-JFF-App/1.0',
          },
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          if (kDebugMode) {
            print('AudioCache: ✅ Found audio for $hymnId via mapping');
          }
          return true;
        }
      } catch (e) {
        if (kDebugMode) {
          print('AudioCache: ❌ Mapping URL check failed for $hymnId: $e');
        }
      }
    }

    // Last resort: try just the number
    final numberMatch = RegExp(r'^(\d+)').firstMatch(hymnId);
    if (numberMatch != null) {
      final numberOnly = numberMatch.group(1)!;
      final numberUrl =
          'https://raw.githubusercontent.com/manasseh-randriamitsiry/Fihirana-audio/main/$numberOnly.mp3';

      try {
        if (kDebugMode) {
          print('AudioCache: Checking number-only URL for $hymnId: $numberUrl');
        }

        final response = await http.head(
          Uri.parse(numberUrl),
          headers: {
            'User-Agent': 'Fihirana-JFF-App/1.0',
          },
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          if (kDebugMode) {
            print('AudioCache: ✅ Found audio for $hymnId using number-only');
          }
          return true;
        }
      } catch (e) {
        if (kDebugMode) {
          print('AudioCache: ❌ Number-only URL check failed for $hymnId: $e');
        }
      }
    }

    if (kDebugMode) {
      print('AudioCache: ❌ No audio found for $hymnId');
    }
    return false;
  }

  /// Batch check multiple hymns from network
  Future<Map<String, bool>> _batchCheckNetworkAvailability(
      List<String> hymnIds) async {
    final Map<String, bool> results = {};
    const batchSize =
        10; // Process in smaller batches to avoid overwhelming the network

    for (int i = 0; i < hymnIds.length; i += batchSize) {
      final end =
          (i + batchSize < hymnIds.length) ? i + batchSize : hymnIds.length;
      final batch = hymnIds.sublist(i, end);

      if (kDebugMode) {
        print(
            'AudioCache: Processing batch ${i ~/ batchSize + 1} of ${(hymnIds.length + batchSize - 1) ~/ batchSize} (${batch.length} hymns)');
      }

      final List<Future<bool>> futures = [];

      // Create futures for this batch
      for (final hymnId in batch) {
        futures.add(_checkActualAudioAvailability(hymnId));
      }

      // Wait for this batch to complete
      try {
        final List<bool> networkResults = await Future.wait(
          futures,
          eagerError: false, // Don't fail all if one fails
        ).timeout(
            const Duration(seconds: 30)); // Add timeout for the entire batch

        // Combine results for this batch
        for (int j = 0; j < batch.length; j++) {
          results[batch[j]] = networkResults[j];
        }
      } catch (e) {
        if (kDebugMode) {
          print('AudioCache: Batch timeout or error, marking as failed: $e');
        }
        // Mark all in this batch as failed if timeout occurs
        for (final hymnId in batch) {
          results[hymnId] = false;
        }
      }

      // Small delay between batches to be respectful to the server
      if (i + batchSize < hymnIds.length) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    return results;
  }

  /// Cache audio availability result
  Future<void> _cacheAudioAvailability(String hymnId, bool hasAudio) async {
    try {
      final db = await database;
      await db.insert(
        _tableName,
        {
          'hymn_id': hymnId,
          'has_audio': hasAudio ? 1 : 0,
          'last_checked': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      if (kDebugMode) {
        print('AudioCache: Error caching $hymnId: $e');
      }
    }
  }

  /// Preload audio availability for common hymns
  Future<void> preloadCommonHymns(List<String> hymnIds) async {
    if (kDebugMode) {
      print('AudioCache: Preloading ${hymnIds.length} common hymns');
    }
    await checkMultipleAudioExists(hymnIds);
  }

  /// Clear expired cache entries
  Future<void> clearExpiredCache() async {
    try {
      final db = await database;
      final expiryTime =
          DateTime.now().subtract(_cacheExpiry).millisecondsSinceEpoch;

      await db.delete(
        _tableName,
        where: 'last_checked < ?',
        whereArgs: [expiryTime],
      );

      if (kDebugMode) {
        print('AudioCache: Cleared expired cache entries');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AudioCache: Error clearing expired cache: $e');
      }
    }
  }

  /// Clear all cache
  Future<void> clearAllCache() async {
    try {
      final db = await database;
      await db.delete(_tableName);
      _memoryCache.clear();
      if (kDebugMode) {
        print('AudioCache: Cleared all cache');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AudioCache: Error clearing cache: $e');
      }
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(_tableName);

      int totalChecked = maps.length;
      int withAudio = maps.where((map) => map['has_audio'] == 1).length;
      int withoutAudio = totalChecked - withAudio;

      return {
        'total_checked': totalChecked,
        'with_audio': withAudio,
        'without_audio': withoutAudio,
        'memory_cache_size': _memoryCache.length,
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'total_checked': 0,
        'with_audio': 0,
        'without_audio': 0,
        'memory_cache_size': _memoryCache.length,
      };
    }
  }

  /// Get count of hymns with audio from cache (faster than full check)
  Future<int> getAudioCountFromCache() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
          'SELECT COUNT(*) as count FROM $_tableName WHERE has_audio = 1');
      return result.first['count'] as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
