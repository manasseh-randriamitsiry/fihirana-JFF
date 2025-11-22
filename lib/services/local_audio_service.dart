import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'storage_manager.dart';

class LocalAudioService {
  static final LocalAudioService _instance = LocalAudioService._internal();
  factory LocalAudioService() => _instance;
  LocalAudioService._internal();

  final StorageManager _storageManager = StorageManager();
  bool _initialized = false;

  /// Initialize the local audio service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await _storageManager.initialize();
      _initialized = true;

      // Clean up any temporary files
      await _storageManager.cleanupTempFiles();

      if (kDebugMode) {
        print('LocalAudioService: Initialized with storage manager');
        print(
            'LocalAudioService: Audio directory: ${_storageManager.audioStorageDir}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('LocalAudioService: Failed to initialize: $e');
      }
    }
  }

  /// Get the local file path for a hymn
  String? getLocalAudioPath(String hymnId) {
    if (!_initialized) return null;

    // Try different possible filenames
    final possibleNames = [
      '$hymnId.mp3',
      '$hymnId.mp3', // In case hymnId already has extension
    ];

    for (final name in possibleNames) {
      final filePath = path.join(_storageManager.audioStorageDir, name);
      final file = File(filePath);
      if (file.existsSync()) {
        return filePath;
      }
    }

    return null;
  }

  /// Check if audio exists locally
  bool hasLocalAudio(String hymnId) {
    return getLocalAudioPath(hymnId) != null;
  }

  /// Download audio file for a hymn
  Future<bool> downloadAudio(String hymnId, String audioUrl,
      {Function(double)? onProgress}) async {
    if (!_initialized) {
      await initialize();
    }

    // Check if we can write to storage
    if (!await _storageManager.canWriteToStorage()) {
      if (kDebugMode) {
        print('LocalAudioService: Cannot write to storage, reinitializing...');
      }
      await _storageManager.initialize();
      // Don't check again to avoid infinite loop - just try the download
    }

    try {
      // Check if file already exists
      if (hasLocalAudio(hymnId)) {
        if (kDebugMode) {
          print('LocalAudioService: Audio for $hymnId already exists locally');
        }
        return true;
      }

      if (kDebugMode) {
        print(
            'LocalAudioService: Downloading audio for $hymnId from $audioUrl');
      }

      // Get filename from URL or use hymnId
      final fileName = audioUrl.split('/').last;
      final filePath = path.join(_storageManager.audioStorageDir, fileName);

      // Create a temporary file for download
      final tempFilePath = '$filePath.tmp';
      final tempFile = File(tempFilePath);

      // Configure HTTP client with timeout and retry
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(audioUrl))
        ..headers.addAll({
          'User-Agent': 'Fihirana-JFF/1.0',
          'Accept': 'audio/mpeg,audio/*',
          'Connection': 'keep-alive',
        });

      // Send request with timeout
      final streamedResponse = await client.send(request).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Download timeout for $hymnId');
        },
      );

      if (streamedResponse.statusCode != 200) {
        client.close();
        if (kDebugMode) {
          print(
              'LocalAudioService: Failed to download $hymnId: ${streamedResponse.statusCode}');
        }
        return false;
      }

      final contentLength = streamedResponse.contentLength ?? 0;
      if (contentLength == 0) {
        client.close();
        if (kDebugMode) {
          print('LocalAudioService: No content for $hymnId');
        }
        return false;
      }

      // Stream directly to file to avoid memory issues
      final sink = tempFile.openWrite();
      int downloadedBytes = 0;

      try {
        await for (final chunk in streamedResponse.stream) {
          sink.add(chunk);
          downloadedBytes += chunk.length;

          if (onProgress != null && contentLength > 0) {
            final progress = downloadedBytes / contentLength;
            if (kDebugMode && downloadedBytes % (1024 * 100) == 0) {
              // Log every 100KB
              if (kDebugMode) {
                print(
                  'LocalAudioService: Download progress for $hymnId: ${(progress * 100).toInt()}%');
              }
            }
            onProgress(progress);
          }
        }

        await sink.close();

        // Verify file size matches expected
        final actualSize = await tempFile.length();
        if (contentLength > 0 && actualSize != contentLength) {
          await tempFile.delete();
          client.close();
          if (kDebugMode) {
            print(
                'LocalAudioService: Size mismatch for $hymnId: expected $contentLength, got $actualSize');
          }
          return false;
        }

        // Move temp file to final location
        await tempFile.rename(filePath);

        if (kDebugMode) {
          print(
              'LocalAudioService: Successfully downloaded $hymnId to $filePath ($actualSize bytes)');
        }

        return true;
      } catch (e) {
        await sink.close();
        if (await tempFile.exists()) {
          await tempFile.delete();
        }

        // Handle permission errors specifically
        if (e.toString().contains('Operation not permitted') ||
            e.toString().contains('Permission denied')) {
          if (kDebugMode) {
            print(
                'LocalAudioService: Permission denied for $hymnId, trying fallback location');
          }
          // Try to reinitialize storage with fallback
          await _storageManager.initialize();
          return false;
        }

        rethrow;
      } finally {
        client.close();
      }
    } catch (e) {
      if (kDebugMode) {
        print('LocalAudioService: Error downloading $hymnId: $e');
      }
      return false;
    }
  }

  /// Get the size of local audio directory
  Future<int> getLocalAudioSize() async {
    if (!_initialized) return 0;

    try {
      final dir = Directory(_storageManager.audioStorageDir);
      if (!await dir.exists()) return 0;

      int totalSize = 0;
      final entities = dir.list();
      await for (final entity in entities) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      if (kDebugMode) {
        print('LocalAudioService: Error calculating size: $e');
      }
      return 0;
    }
  }

  /// Get count of locally stored audio files
  Future<int> getLocalAudioCount() async {
    if (!_initialized) return 0;

    try {
      final dir = Directory(_storageManager.audioStorageDir);
      if (!await dir.exists()) return 0;

      final stream = dir.list();
      final files = <FileSystemEntity>[];
      await for (final entity in stream) {
        if (entity is File && entity.path.endsWith('.mp3')) {
          files.add(entity);
        }
      }
      return files.length;
    } catch (e) {
      if (kDebugMode) {
        print('LocalAudioService: Error counting files: $e');
      }
      return 0;
    }
  }

  /// Delete local audio file
  Future<bool> deleteLocalAudio(String hymnId) async {
    if (!_initialized) return false;

    try {
      final localPath = getLocalAudioPath(hymnId);
      if (localPath == null) return false;

      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
        if (kDebugMode) {
          print('LocalAudioService: Deleted local audio for $hymnId');
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('LocalAudioService: Error deleting $hymnId: $e');
      }
      return false;
    }
  }

  /// Clear all local audio files
  Future<void> clearAllLocalAudio() async {
    if (!_initialized) return;

    try {
      final dir = Directory(_storageManager.audioStorageDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create();
        if (kDebugMode) {
          print('LocalAudioService: Cleared all local audio files');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('LocalAudioService: Error clearing files: $e');
      }
    }
  }

  /// Get list of all locally stored hymn IDs
  Future<Set<String>> getLocalHymnIds() async {
    if (!_initialized) return <String>{};

    try {
      final dir = Directory(_storageManager.audioStorageDir);
      if (!await dir.exists()) return <String>{};

      final stream = dir.list();
      final files = <FileSystemEntity>[];
      await for (final entity in stream) {
        if (entity is File && entity.path.endsWith('.mp3')) {
          files.add(entity);
        }
      }

      final hymnIds = <String>{};
      for (final file in files) {
        final fileName = path.basenameWithoutExtension(file.path);
        hymnIds.add(fileName);
      }

      return hymnIds;
    } catch (e) {
      if (kDebugMode) {
        print('LocalAudioService: Error getting local hymn IDs: $e');
      }
      return <String>{};
    }
  }

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    final stats = await _storageManager.getStorageStats();
    return {
      'totalFiles': await getLocalAudioCount(),
      'totalSize': await getLocalAudioSize(),
      'directory': _storageManager.audioStorageDir,
      'userFriendlyPath': _storageManager.getUserFriendlyPath(),
      'initialized': _initialized,
      'availableSpace': stats['availableSpace'] ?? 0,
      'formattedSize': _storageManager.formatBytes(await getLocalAudioSize()),
    };
  }
}
