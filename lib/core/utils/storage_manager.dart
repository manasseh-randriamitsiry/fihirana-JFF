import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class StorageManager {
  static final StorageManager _instance = StorageManager._internal();
  factory StorageManager() => _instance;
  StorageManager._internal();

  late String _baseStorageDir;
  late String _audioStorageDir;
  bool _initialized = false;

  /// Initialize storage directories
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      Directory? baseDir;

      if (Platform.isAndroid) {
        // Try app-specific external storage first (more user-accessible than internal)
        try {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            // Use app-specific external storage path
            baseDir = Directory(path.join(externalDir.path, 'FihiranaJFF'));
            if (kDebugMode) {
              print('StorageManager: Using external storage: ${baseDir.path}');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('StorageManager: External storage not available: $e');
          }
        }
      }

      // Fallback to application documents directory
      if (baseDir == null) {
        final directory = await getApplicationDocumentsDirectory();
        baseDir = Directory(path.join(directory.path, 'FihiranaJFF'));
        if (kDebugMode) {
          print('StorageManager: Using internal storage: ${baseDir.path}');
        }
      }

      _baseStorageDir = baseDir.path;
      _audioStorageDir = path.join(_baseStorageDir, 'Audio');

      // Create directories if they don't exist
      await _createDirectories();

      _initialized = true;
      if (kDebugMode) {
        print(
            'StorageManager: Initialized with base directory: $_baseStorageDir');
        print('StorageManager: Audio directory: $_audioStorageDir');
      }
    } catch (e) {
      if (kDebugMode) {
        print('StorageManager: Failed to initialize: $e');
      }
      rethrow;
    }
  }

  /// Create necessary directories
  Future<void> _createDirectories() async {
    final directories = [
      Directory(_baseStorageDir),
      Directory(_audioStorageDir),
    ];

    for (final dir in directories) {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
        if (kDebugMode) {
          print('StorageManager: Created directory: ${dir.path}');
        }
      }
    }
  }

  /// Get audio storage directory
  String get audioStorageDir => _audioStorageDir;

  /// Get base storage directory
  String get baseStorageDir => _baseStorageDir;

  /// Get user-friendly storage path for display
  String getUserFriendlyPath() {
    if (Platform.isAndroid) {
      // Return a more user-friendly path for Android
      if (_baseStorageDir.contains('Android/data')) {
        return 'App Storage (FihiranaJFF)';
      }
      return _baseStorageDir;
    }
    return _baseStorageDir;
  }

  /// Check if storage is accessible
  bool get isInitialized => _initialized;

  /// Test if we can write to the storage directory
  Future<bool> canWriteToStorage() async {
    if (!_initialized) return false;

    try {
      // Ensure directory exists first
      final dir = Directory(_audioStorageDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final testFile = File(path.join(_audioStorageDir, '.test_write'));
      await testFile.writeAsString('test');
      await testFile.delete();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('StorageManager: Cannot write to storage: $e');
      }
      return false;
    }
  }

  /// Get available storage space (in bytes)
  Future<int> getAvailableStorageSpace() async {
    try {
      if (Platform.isAndroid) {
        // For Android, try to get external storage space
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          final stat = await externalDir.parent.stat();
          return stat.size;
        }
      }

      // Fallback: return a reasonable estimate
      return 1024 * 1024 * 1024; // 1GB as fallback
    } catch (e) {
      if (kDebugMode) {
        print('StorageManager: Error getting storage space: $e');
      }
      return 0;
    }
  }

  /// Clean up temporary files
  Future<void> cleanupTempFiles() async {
    if (!_initialized) return;

    try {
      final baseDir = Directory(_baseStorageDir);
      await for (final entity in baseDir.list()) {
        if (entity is File && entity.path.endsWith('.tmp')) {
          await entity.delete();
          if (kDebugMode) {
            print('StorageManager: Cleaned up temp file: ${entity.path}');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('StorageManager: Error cleaning up temp files: $e');
      }
    }
  }

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    if (!_initialized) return {};

    try {
      final audioDir = Directory(_audioStorageDir);
      int totalSize = 0;
      int fileCount = 0;

      if (await audioDir.exists()) {
        await for (final entity in audioDir.list()) {
          if (entity is File && entity.path.endsWith('.mp3')) {
            totalSize += await entity.length();
            fileCount++;
          }
        }
      }

      final availableSpace = await getAvailableStorageSpace();

      return {
        'totalSize': totalSize,
        'fileCount': fileCount,
        'availableSpace': availableSpace,
        'audioDirectory': _audioStorageDir,
        'userFriendlyPath': getUserFriendlyPath(),
      };
    } catch (e) {
      if (kDebugMode) {
        print('StorageManager: Error getting storage stats: $e');
      }
      return {};
    }
  }

  /// Format bytes to human readable format
  String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
