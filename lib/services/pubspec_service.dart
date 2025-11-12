import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

class PubspecService {
  static String? _cachedVersion;
  static Map<String, dynamic>? _cachedPubspec;

  static Future<String> getAppVersion() async {
    if (_cachedVersion != null) {
      return _cachedVersion!;
    }

    try {
      // Try to read from pubspec.yaml using rootBundle (Flutter assets)
      final content = await rootBundle.loadString('pubspec.yaml');
      final lines = content.split('\n');
      
      for (final line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.startsWith('version:')) {
          _cachedVersion = trimmedLine.substring(8).trim();
          return _cachedVersion!;
        }
      }

      // Fallback to package_info_plus
      final packageInfo = await PackageInfo.fromPlatform();
      _cachedVersion = packageInfo.version;
      return _cachedVersion!;
    } catch (e) {
      // Final fallback to package_info_plus
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        _cachedVersion = packageInfo.version;
        return _cachedVersion!;
      } catch (e) {
        return '1.0.0'; // Default fallback
      }
    }
  }

  static Future<Map<String, dynamic>> getPubspecData() async {
    if (_cachedPubspec != null) {
      return _cachedPubspec!;
    }

    try {
      final content = await rootBundle.loadString('pubspec.yaml');
      
      // Simple YAML parser for basic structure
      final Map<String, dynamic> pubspecData = {};
      final lines = content.split('\n');
      String? currentKey;
      List<String> currentList = [];
      bool inList = false;
      
      for (final line in lines) {
        final trimmedLine = line.trim();
        
        // Skip comments and empty lines
        if (trimmedLine.isEmpty || trimmedLine.startsWith('#')) {
          continue;
        }
        
        // Check for key-value pairs
        if (trimmedLine.contains(':') && !trimmedLine.startsWith(' ')) {
          // Save previous list if exists
          if (inList && currentKey != null) {
            pubspecData[currentKey] = currentList;
            currentList.clear();
          }
          
          final parts = trimmedLine.split(':');
          currentKey = parts[0].trim();
          final value = parts.length > 1 ? parts[1].trim() : '';
          
          if (value.isEmpty) {
            inList = true;
          } else {
            pubspecData[currentKey] = value;
            inList = false;
          }
        } else if (trimmedLine.startsWith(' ') && inList && currentKey != null) {
          // List item
          final listItem = trimmedLine.trim().startsWith('-') 
              ? trimmedLine.substring(1).trim()
              : trimmedLine.trim();
          if (listItem.isNotEmpty) {
            currentList.add(listItem);
          }
        }
      }
      
      // Save final list if exists
      if (inList && currentKey != null && currentList.isNotEmpty) {
        pubspecData[currentKey] = currentList;
      }
      
      _cachedPubspec = pubspecData;
      return pubspecData;
    } catch (e) {
      return {};
    }
  }

  static Future<String> getAppName() async {
    try {
      final pubspecData = await getPubspecData();
      return pubspecData['name'] ?? 'Fihirana';
    } catch (e) {
      return 'Fihirana';
    }
  }

  static Future<String> getAppDescription() async {
    try {
      final pubspecData = await getPubspecData();
      return pubspecData['description'] ?? 'A new Flutter project.';
    } catch (e) {
      return 'A new Flutter project.';
    }
  }

  static void clearCache() {
    _cachedVersion = null;
    _cachedPubspec = null;
  }

  // Force refresh the version (useful for testing)
  static Future<String> refreshAppVersion() async {
    clearCache();
    return await getAppVersion();
  }
}