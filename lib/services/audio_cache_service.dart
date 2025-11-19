import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;

class AudioCacheService {
  static final AudioCacheService _instance = AudioCacheService._internal();
  factory AudioCacheService() => _instance;
  AudioCacheService._internal();

  Database? _database;
  final Map<String, bool> _memoryCache = {};
  final Set<String> _pendingChecks = {};
  static const String _tableName = 'audio_cache';
  static const Duration _cacheExpiry = Duration(days: 7); // Cache for 7 days

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

  /// Check if audio exists for a hymn (uses cache first)
  Future<bool> checkAudioExists(String hymnId) async {
    // Check memory cache first
    if (_memoryCache.containsKey(hymnId)) {
      print('AudioCache: Found $hymnId in memory cache: ${_memoryCache[hymnId]}');
      return _memoryCache[hymnId]!;
    }

    // Check if we're already checking this hymn
    if (_pendingChecks.contains(hymnId)) {
      print('AudioCache: Already checking $hymnId, waiting...');
      
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
        final lastChecked = DateTime.fromMillisecondsSinceEpoch(maps.first['last_checked']);
        final hasAudio = maps.first['has_audio'] == 1;
        
        // Check if cache is still valid
        if (DateTime.now().difference(lastChecked) < _cacheExpiry) {
          print('AudioCache: Found $hymnId in database cache: $hasAudio');
          _memoryCache[hymnId] = hasAudio;
          return hasAudio;
        } else {
          print('AudioCache: Cache expired for $hymnId, refreshing...');
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
      
      print('AudioCache: Checked $hymnId from network: $hasAudio');
      return hasAudio;
    } catch (e) {
      print('AudioCache: Error checking $hymnId: $e');
      return false;
    } finally {
      _pendingChecks.remove(hymnId);
    }
  }

  /// Check multiple hymns at once (batch operation)
  Future<Map<String, bool>> checkMultipleAudioExists(List<String> hymnIds) async {
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
      print('AudioCache: All hymns found in memory cache');
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
      final lastChecked = DateTime.fromMillisecondsSinceEpoch(map['last_checked']);
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
      print('AudioCache: Checking ${networkCheckIds.length} hymns from network');
      final networkResults = await _batchCheckNetworkAvailability(networkCheckIds);
      
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
    final audioUrl = 'https://raw.githubusercontent.com/manasseh-randriamitsiry/Fihirana-audio/main/$hymnId.mp3';
    
    try {
      final response = await http.head(
        Uri.parse(audioUrl),
      ).timeout(const Duration(seconds: 3));
      
      return response.statusCode == 200;
    } catch (e) {
      print('AudioCache: Network check failed for $hymnId: $e');
      return false;
    }
  }

  /// Batch check multiple hymns from network
  Future<Map<String, bool>> _batchCheckNetworkAvailability(List<String> hymnIds) async {
    final Map<String, bool> results = {};
    final List<Future<bool>> futures = [];

    // Create futures for all checks
    for (final hymnId in hymnIds) {
      futures.add(_checkActualAudioAvailability(hymnId));
    }

    // Wait for all checks to complete
    final List<bool> networkResults = await Future.wait(
      futures,
      eagerError: false, // Don't fail all if one fails
    );

    // Combine results
    for (int i = 0; i < hymnIds.length; i++) {
      results[hymnIds[i]] = networkResults[i];
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
      print('AudioCache: Error caching $hymnId: $e');
    }
  }

  /// Preload audio availability for common hymns
  Future<void> preloadCommonHymns(List<String> hymnIds) async {
    print('AudioCache: Preloading ${hymnIds.length} common hymns');
    await checkMultipleAudioExists(hymnIds);
  }

  /// Clear expired cache entries
  Future<void> clearExpiredCache() async {
    try {
      final db = await database;
      final expiryTime = DateTime.now().subtract(_cacheExpiry).millisecondsSinceEpoch;
      
      await db.delete(
        _tableName,
        where: 'last_checked < ?',
        whereArgs: [expiryTime],
      );
      
      print('AudioCache: Cleared expired cache entries');
    } catch (e) {
      print('AudioCache: Error clearing expired cache: $e');
    }
  }

  /// Clear all cache
  Future<void> clearAllCache() async {
    try {
      final db = await database;
      await db.delete(_tableName);
      _memoryCache.clear();
      print('AudioCache: Cleared all cache');
    } catch (e) {
      print('AudioCache: Error clearing cache: $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_entries,
          SUM(CASE WHEN has_audio = 1 THEN 1 ELSE 0 END) as with_audio,
          SUM(CASE WHEN has_audio = 0 THEN 1 ELSE 0 END) as without_audio,
          MAX(last_checked) as last_checked
        FROM $_tableName
      ''');

      if (maps.isNotEmpty) {
        return {
          'totalEntries': maps.first['total_entries'] ?? 0,
          'withAudio': maps.first['with_audio'] ?? 0,
          'withoutAudio': maps.first['without_audio'] ?? 0,
          'lastChecked': maps.first['last_checked'] != null 
              ? DateTime.fromMillisecondsSinceEpoch(maps.first['last_checked'])
              : null,
          'memoryCacheSize': _memoryCache.length,
        };
      }

      return {
        'totalEntries': 0,
        'withAudio': 0,
        'withoutAudio': 0,
        'lastChecked': null,
        'memoryCacheSize': _memoryCache.length,
      };
    } catch (e) {
      print('AudioCache: Error getting cache stats: $e');
      return {
        'totalEntries': 0,
        'withAudio': 0,
        'withoutAudio': 0,
        'lastChecked': null,
        'memoryCacheSize': _memoryCache.length,
      };
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