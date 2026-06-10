import 'dart:io';
import 'package:flutter/foundation.dart';

class AudioConfig {
  static const Map<String, String> _supportedFormats = {
    'android': '.mp3',
    'ios': '.m4a',
    'emulator': '.wav',
  };

  static const Map<String, List<String>> _preferredCodecs = {
    'android': ['audio/mp4a-latm', 'audio/mpeg', 'audio/aac'],
    'ios': ['audio/mp4a-latm', 'audio/aac', 'audio/mpeg'],
    'emulator': ['audio/wav', 'audio/pcm', 'audio/mpeg'],
  };

  static Future<bool> get isEmulator async {
    if (!kIsWeb && Platform.isAndroid) {
      return await _isAndroidEmulator();
    }
    return false;
  }

  static bool get isIOSDevice => !kIsWeb && Platform.isIOS;

  static Future<bool> get isAndroidDevice async {
    if (!kIsWeb && Platform.isAndroid) {
      return !(await isEmulator);
    }
    return false;
  }

  static Future<String> get preferredFormat async {
    if (await isEmulator) return _supportedFormats['emulator']!;
    if (isIOSDevice) return _supportedFormats['ios']!;
    return _supportedFormats['android']!;
  }

  static Future<List<String>> get preferredCodecs async {
    if (await isEmulator) return _preferredCodecs['emulator']!;
    if (isIOSDevice) return _preferredCodecs['ios']!;
    final isAndroid = await isAndroidDevice;
    if (isAndroid) return _preferredCodecs['android']!;
    return _preferredCodecs['android']!;
  }

  static Future<bool> _isAndroidEmulator() async {
    try {
      // Check for common emulator indicators
      final result = await Process.run('getprop', ['ro.kernel.qemu']);
      if (result.exitCode == 0) {
        return true;
      }

      // Check for emulator-specific properties
      final qemuCheck = await Process.run('getprop', ['ro.kernel.qemu']);
      if (qemuCheck.exitCode == 0) {
        return true;
      }

      // Check for generic emulator build
      final buildCheck = await Process.run('getprop', ['ro.build.fingerprint']);
      if (buildCheck.exitCode == 0) {
        final fingerprint = buildCheck.stdout.toString().toLowerCase();
        return fingerprint.contains('generic') ||
            fingerprint.contains('vbox') ||
            fingerprint.contains('emulator');
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('AudioConfig: Error checking for emulator: $e');
      }
      return false;
    }
  }

  static Future<Map<String, dynamic>> getAudioPlayerConfig() async {
    final config = <String, dynamic>{};
    final isEmulatorDevice = await isEmulator;

    if (isEmulatorDevice) {
      // Emulator-specific configuration
      config['androidAudioEffects'] = [];
      config['bufferSize'] = 8192; // Smaller buffer for emulator
      config['preload'] = false; // Disable preloading for emulator
      config['timeout'] = const Duration(seconds: 15); // Shorter timeout
    } else {
      // Physical device configuration
      config['androidAudioEffects'] = [];
      config['bufferSize'] = 16384; // Larger buffer for physical devices
      config['preload'] = true; // Enable preloading for physical devices
      config['timeout'] = const Duration(seconds: 30); // Standard timeout
    }

    return config;
  }

  static Future<String> getFallbackUrl(String originalUrl) async {
    final isEmulatorDevice = await isEmulator;
    if (isEmulatorDevice && originalUrl.contains('.mp3')) {
      // For emulator, try to find a .wav version or use a more compatible format
      return originalUrl.replaceAll('.mp3', '.wav');
    }
    return originalUrl;
  }

  static bool isFormatSupported(String format) {
    final supportedExtensions = ['.mp3', '.wav', '.m4a', '.aac'];
    return supportedExtensions.any((ext) => format.toLowerCase().endsWith(ext));
  }

  static String getMimeTypeForFormat(String format) {
    switch (format.toLowerCase()) {
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.m4a':
      case '.aac':
        return 'audio/mp4a-latm';
      default:
        return 'audio/mpeg';
    }
  }
}
