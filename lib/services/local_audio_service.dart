import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class LocalAudioService {
  static final LocalAudioService _instance = LocalAudioService._internal();
  factory LocalAudioService() => _instance;
  LocalAudioService._internal();

  late String _audioDir;
  bool _initialized = false;

  /// Initialize the local audio service
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      _audioDir = path.join(directory.path, 'audio');
      
      // Create audio directory if it doesn't exist
      final dir = Directory(_audioDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      _initialized = true;
      if (kDebugMode) {
        print('LocalAudioService: Initialized with directory: $_audioDir');
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
      '${hymnId}.mp3', // In case hymnId already has extension
    ];
    
    for (final name in possibleNames) {
      final filePath = path.join(_audioDir, name);
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

    try {
      // Check if file already exists
      if (hasLocalAudio(hymnId)) {
        if (kDebugMode) {
          print('LocalAudioService: Audio for $hymnId already exists locally');
        }
        return true;
      }

      if (kDebugMode) {
        print('LocalAudioService: Downloading audio for $hymnId from $audioUrl');
      }

      // Download the file
      final request = http.Request('GET', Uri.parse(audioUrl));
      final response = await request.send();

      if (response.statusCode != 200) {
        if (kDebugMode) {
          print('LocalAudioService: Failed to download $hymnId: ${response.statusCode}');
        }
        return false;
      }

      final contentLength = response.contentLength ?? 0;
      if (contentLength == 0) {
        if (kDebugMode) {
          print('LocalAudioService: No content for $hymnId');
        }
        return false;
      }

      // Get filename from URL or use hymnId
      final fileName = audioUrl.split('/').last;
      final filePath = path.join(_audioDir, fileName);
      final file = File(filePath);

      // Save the file with progress tracking
      final bytes = <int>[];
      int downloadedBytes = 0;

      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        downloadedBytes += chunk.length;
        
        if (onProgress != null && contentLength > 0) {
          final progress = downloadedBytes / contentLength;
          onProgress(progress);
        }
      }

      await file.writeAsBytes(bytes);
      
      if (kDebugMode) {
        print('LocalAudioService: Successfully downloaded $hymnId to $filePath');
      }
      
      return true;
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
      final dir = Directory(_audioDir);
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
      final dir = Directory(_audioDir);
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
      final dir = Directory(_audioDir);
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
      final dir = Directory(_audioDir);
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
    return {
      'totalFiles': await getLocalAudioCount(),
      'totalSize': await getLocalAudioSize(),
      'directory': _audioDir,
      'initialized': _initialized,
    };
  }
}