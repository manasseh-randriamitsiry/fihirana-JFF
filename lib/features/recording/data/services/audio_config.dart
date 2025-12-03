import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:record/record.dart';

class AudioConfig {
  static Future<bool> get isEmulator async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.isPhysicalDevice == false;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.isPhysicalDevice == false;
    }
    return false;
  }

  static Future<AudioEncoder> get preferredFormat async {
    final isEmulator = await AudioConfig.isEmulator;
    return isEmulator ? AudioEncoder.wav : AudioEncoder.aacLc;
  }

  static const int sampleRate = 44100;
  static const int bitRate = 128000;
  static const int channels = 1; // Mono
}