import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'audio_service.dart';
import 'notification_service.dart';
import '../models/hymn.dart';

class AudioForegroundService extends GetxService {
  static AudioForegroundService? _instance;
  static AudioForegroundService get instance {
    _instance ??= AudioForegroundService._internal();
    return _instance!;
  }
  
  factory AudioForegroundService() => instance;
  AudioForegroundService._internal();

  bool _isForeground = false;

  @override
  void onInit() {
    super.onInit();
    
    // Listen to audio service state changes
    final audioService = AudioService.instance;
    ever(audioService.currentPlayingHymnIdRx, (String hymnId) {
      if (hymnId.isNotEmpty && !_isForeground) {
        _startForegroundService();
      } else if (hymnId.isEmpty && _isForeground) {
        _stopForegroundService();
      }
    });
  }

  void _startForegroundService() {
    if (!kIsWeb) {
      _isForeground = true;
      // Update notification to make it persistent
      final audioService = AudioService.instance;
      final currentHymn = audioService.currentHymn;
      if (currentHymn != null) {
        NotificationService.showAudioPlayerNotification(currentHymn!, audioService.isPlaying);
      }
    }
  }

  void _stopForegroundService() {
    if (!kIsWeb) {
      _isForeground = false;
      NotificationService.hideAudioPlayerNotification();
    }
  }

  void updateNotification(Hymn? hymn, bool isPlaying) {
    if (_isForeground && hymn != null) {
      NotificationService.updateAudioPlayerNotification(hymn, isPlaying);
    }
  }

  @override
  void onClose() {
    _stopForegroundService();
    super.onClose();
  }
}