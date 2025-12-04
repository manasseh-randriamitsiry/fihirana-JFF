import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AudioFileMapping {
  static final AudioFileMapping _instance = AudioFileMapping._internal();
  factory AudioFileMapping() => _instance;
  AudioFileMapping._internal();

  Map<String, String>? _audioFileMapping;
  DateTime? _lastUpdated;
  static const Duration _cacheExpiry = Duration(hours: 24);

  /// Get the actual filename for a hymn ID
  String? getAudioFilename(String hymnId) {
    if (_audioFileMapping == null || isCacheExpired()) {
      if (kDebugMode) {
        print('AudioFileMapping: Cache is null or expired for $hymnId');
      }
      return null;
    }
    final filename = _audioFileMapping![hymnId];
    if (kDebugMode) {
      print('AudioFileMapping: getAudioFilename($hymnId) -> $filename');
    }
    return filename;
  }

  /// Check if cache is expired
  bool isCacheExpired() {
    if (_lastUpdated == null) return true;
    return DateTime.now().difference(_lastUpdated!) > _cacheExpiry;
  }

  /// Fetch the list of audio files from GitHub and create mapping
  Future<void> updateAudioFileMapping({int retries = 3}) async {
    int attempt = 0;
    Exception? lastError;

    while (attempt < retries) {
      try {
        if (kDebugMode) {
          print('AudioFileMapping: Fetching audio file list from GitHub (attempt ${attempt + 1}/$retries)...');
        }

        final response = await http.get(
          Uri.parse('https://api.github.com/repos/manasseh-randriamitsiry/Fihirana-audio/contents'),
          headers: {
            'Accept': 'application/vnd.github.v3+json',
            'User-Agent': 'Fihirana-JFF-App/1.0',
          },
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final List<dynamic> files = json.decode(response.body);
          final Map<String, String> mapping = {};

          for (final file in files) {
            if (file['name'] != null && 
                file['name'].toString().endsWith('.mp3') &&
                file['type'] == 'file') {
              final fileName = file['name'] as String;
              // Remove .mp3 extension to get the hymn ID
              final hymnId = fileName.replaceAll('.mp3', '');
              mapping[hymnId] = fileName;
              
              // Also map by just the number for backward compatibility
              final match = RegExp(r'^(\d+)').firstMatch(fileName);
              if (match != null) {
                final numberOnly = match.group(1)!;
                mapping[numberOnly] = fileName;
              }
            }
          }

          _audioFileMapping = mapping;
          _lastUpdated = DateTime.now();

          if (kDebugMode) {
            print('AudioFileMapping: ✅ Successfully updated mapping with ${mapping.length} files');
            print('AudioFileMapping: Sample mappings: ${mapping.entries.take(5).toList()}');
            // Check if our test IDs are mapped
            final testIds = ['1', '10', '100'];
            for (final id in testIds) {
              final filename = getAudioFilename(id);
              print('AudioFileMapping: $id -> $filename');
            }
          }
          
          // Success - exit retry loop
          return;
          
        } else if (response.statusCode == 403) {
          if (kDebugMode) {
            print('AudioFileMapping: ⚠️ GitHub API rate limit exceeded (403)');
          }
          lastError = Exception('GitHub API rate limit exceeded');
          // Don't retry on rate limit - wait for cache to expire
          break;
          
        } else {
          if (kDebugMode) {
            print('AudioFileMapping: ❌ Failed to fetch file list: ${response.statusCode}');
          }
          lastError = Exception('HTTP ${response.statusCode}');
        }
      } catch (e) {
        if (kDebugMode) {
          print('AudioFileMapping: ❌ Error updating mapping (attempt ${attempt + 1}/$retries): $e');
        }
        lastError = e is Exception ? e : Exception(e.toString());
      }

      attempt++;
      if (attempt < retries) {
        // Wait before retry (exponential backoff)
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }

    // If we get here, all retries failed
    if (kDebugMode) {
      print('AudioFileMapping: ❌ Failed to update mapping after $retries attempts');
      if (lastError != null) {
        print('AudioFileMapping: Last error: $lastError');
      }
      if (_audioFileMapping != null) {
        print('AudioFileMapping: ⚠️ Using cached mapping with ${_audioFileMapping!.length} files');
      }
    }
  }

  /// Get all available hymn IDs that have audio
  Set<String> getAvailableHymnIds() {
    if (_audioFileMapping == null || isCacheExpired()) {
      return <String>{};
    }
    return _audioFileMapping!.keys.toSet();
  }

  /// Check if a hymn has audio available
  bool hasAudio(String hymnId) {
    if (_audioFileMapping == null || isCacheExpired()) {
      return false;
    }
    return _audioFileMapping!.containsKey(hymnId);
  }

  /// Get the full URL for a hymn's audio file
  String? getAudioUrl(String hymnId) {
    final filename = getAudioFilename(hymnId);
    if (filename == null) return null;
    return 'https://raw.githubusercontent.com/manasseh-randriamitsiry/Fihirana-audio/main/$filename';
  }

  /// Force refresh the mapping
  Future<void> refresh() async {
    _audioFileMapping = null;
    _lastUpdated = null;
    await updateAudioFileMapping();
  }

  /// Get mapping statistics
  Map<String, dynamic> getStats() {
    return {
      'totalFiles': _audioFileMapping?.length ?? 0,
      'lastUpdated': _lastUpdated?.toIso8601String(),
      'isExpired': isCacheExpired(),
    };
  }

  /// Get all available hymn entries (ID -> filename mapping)
  Map<String, String> getAllAudioFiles() {
    if (_audioFileMapping == null || isCacheExpired()) {
      return {};
    }
    return Map<String, String>.from(_audioFileMapping!);
  }
}