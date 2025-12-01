import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'audio_config.dart';

class AudioFormatValidator {
  static const Map<String, List<String>> _formatCompatibility = {
    'emulator': ['.wav', '.mp3', '.m4a'],
    'android': ['.mp3', '.m4a', '.aac', '.wav'],
    'ios': ['.m4a', '.aac', '.mp3', '.wav'],
  };

  static const Map<String, String> _mimeTypes = {
    '.mp3': 'audio/mpeg',
    '.wav': 'audio/wav',
    '.m4a': 'audio/mp4a-latm',
    '.aac': 'audio/aac',
    '.ogg': 'audio/ogg',
    '.flac': 'audio/flac',
  };

  static Future<bool> isFormatCompatible(String format, {String? deviceType}) async {
    deviceType ??= await _getDeviceType();
    final compatibleFormats = _formatCompatibility[deviceType] ?? _formatCompatibility['android']!;
    return compatibleFormats.contains(format.toLowerCase());
  }

  static Future<String> getBestCompatibleFormat(List<String> availableFormats) async {
    final deviceType = await _getDeviceType();
    final compatibleFormats = _formatCompatibility[deviceType] ?? _formatCompatibility['android']!;
    
    // Find the first compatible format from available formats
    for (String format in availableFormats) {
      if (compatibleFormats.contains(format.toLowerCase())) {
        return format;
      }
    }
    
    // Fallback to most compatible format
    if (deviceType == 'emulator') {
      return '.wav';
    } else if (deviceType == 'ios') {
      return '.m4a';
    } else {
      return '.mp3';
    }
  }

  static Future<String> _getDeviceType() async {
    final isEmulator = await AudioConfig.isEmulator;
    final isAndroidDevice = await AudioConfig.isAndroidDevice;
    
    if (isEmulator) return 'emulator';
    if (AudioConfig.isIOSDevice) return 'ios';
    if (isAndroidDevice) return 'android';
    return 'android'; // Default
  }

  static String? getMimeType(String filePath) {
    final extension = _getFileExtension(filePath);
    return _mimeTypes[extension.toLowerCase()];
  }

  static String _getFileExtension(String filePath) {
    return filePath.split('.').last.toLowerCase();
  }

  static Future<bool> validateAudioFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        if (kDebugMode) {
          print('AudioFormatValidator: File does not exist: $filePath');
        }
        return false;
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        if (kDebugMode) {
          print('AudioFormatValidator: File is empty: $filePath');
        }
        return false;
      }

      // Check file extension
      final extension = _getFileExtension(filePath);
      final mimeType = getMimeType(filePath);
      
      if (mimeType == null) {
        if (kDebugMode) {
          print('AudioFormatValidator: Unsupported format: $extension');
        }
        return false;
      }

      // Check if format is compatible with current device
      if (!(await isFormatCompatible(extension))) {
        if (kDebugMode) {
          final deviceType = await _getDeviceType();
          print('AudioFormatValidator: Format $extension not compatible with $deviceType');
        }
        return false;
      }

      // Try to create audio source to validate file integrity
      try {
        final tempPlayer = AudioPlayer();
        await tempPlayer.setFilePath(filePath);
        await tempPlayer.dispose();
        
        if (kDebugMode) {
          print('AudioFormatValidator: File validation passed: $filePath');
        }
        return true;
      } catch (e) {
        if (kDebugMode) {
          print('AudioFormatValidator: File validation failed: $filePath - $e');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('AudioFormatValidator: Error validating file: $filePath - $e');
      }
      return false;
    }
  }

  static Future<String?> convertFormat(String inputPath, String targetFormat) async {
    try {
      if (kDebugMode) {
        print('AudioFormatValidator: Converting $inputPath to $targetFormat');
      }

      // For now, we'll just validate and return the original path
      // In a full implementation, you would use an audio conversion library
      // like ffmpeg or flutter_audio_converter
      
      final isValid = await validateAudioFile(inputPath);
      if (!isValid) {
        if (kDebugMode) {
          print('AudioFormatValidator: Cannot convert invalid file: $inputPath');
        }
        return null;
      }

      // Check if conversion is needed
      final currentFormat = _getFileExtension(inputPath);
      if (currentFormat == targetFormat.toLowerCase()) {
        if (kDebugMode) {
          print('AudioFormatValidator: No conversion needed, format already matches');
        }
        return inputPath;
      }

      // For emulator, prefer WAV format
      if (await AudioConfig.isEmulator && targetFormat != '.wav') {
        if (kDebugMode) {
          print('AudioFormatValidator: Emulator prefers WAV format');
        }
        // In a real implementation, you would convert to WAV here
        return inputPath; // Return original for now
      }

      return inputPath; // Return original for now
    } catch (e) {
      if (kDebugMode) {
        print('AudioFormatValidator: Error converting format: $e');
      }
      return null;
    }
  }

  static Future<List<String>> getSupportedFormats() async {
    final deviceType = await _getDeviceType();
    return _formatCompatibility[deviceType] ?? _formatCompatibility['android']!;
  }

  static Future<String> getPreferredFormat() async {
    final deviceType = await _getDeviceType();
    switch (deviceType) {
      case 'emulator':
        return '.wav';
      case 'ios':
        return '.m4a';
      case 'android':
        return '.mp3';
      default:
        return '.mp3';
    }
  }

  static Future<Map<String, dynamic>> getAudioFileInfo(String filePath) async {
    try {
      final file = File(filePath);
      final stat = await file.stat();
      final extension = _getFileExtension(filePath);
      final mimeType = getMimeType(filePath);
      
        return {
        'path': filePath,
        'size': stat.size,
        'modified': stat.modified,
        'extension': extension,
        'mimeType': mimeType,
        'isCompatible': await isFormatCompatible(extension),
        'isValid': await validateAudioFile(filePath),
      };
    } catch (e) {
      if (kDebugMode) {
        print('AudioFormatValidator: Error getting file info: $e');
      }
      return {
        'path': filePath,
        'error': e.toString(),
        'isValid': false,
      };
    }
  }
}