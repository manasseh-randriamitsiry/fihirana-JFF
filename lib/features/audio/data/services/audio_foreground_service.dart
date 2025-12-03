import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'audio_service.dart';
import 'package:fihirana/core/utils/notification_service.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';

/// Service to manage audio player notifications in foreground
class AudioForegroundService extends GetxService {
  static AudioForegroundService? _instance;
  bool _isForeground = false;
  Timer? _notificationUpdateTimer;
  late AudioService _audioService;

  AudioForegroundService() {
    _instance = this;
  }

  static AudioForegroundService get instance {
    _instance ??= AudioForegroundService();
    return _instance!;
  }

  @override
  void onInit() {
    super.onInit();

    // Listen to audio service state changes
    _audioService = AudioService.instance;

    // Listen to current hymn changes
    ever(_audioService.currentPlayingHymnIdRx, (String hymnId) {
      if (hymnId.isNotEmpty) {
        if (!_isForeground) {
          _startForegroundService();
        }
      } else {
        if (_isForeground) {
          _stopForegroundService();
        }
      }
    });

    // Listen to player state changes (playing/paused)
    _audioService.playerStateStream.listen((state) {
      if (_isForeground) {
        final currentHymn = _audioService.currentHymn;
        if (currentHymn != null) {
          // Update notification with new playing state
          // This will toggle the locked/dismissible status and button states
          NotificationService.updateAudioPlayerProgress(
            currentHymn,
            state.playing,
            position: _audioService.currentPosition,
            duration: _audioService.duration,
          );
        }
      }
    });

    // Listen to position changes to update progress bar (more frequent updates)
    _audioService.positionStream.listen((position) {
      if (_isForeground && position != null) {
        final currentHymn = _audioService.currentHymn;
        if (currentHymn != null) {
          if (kDebugMode) {
            print(
                'AudioForegroundService: Position received: ${position.inMilliseconds}ms');
          }
          // Update notification immediately with current position
          NotificationService.updateAudioPlayerProgress(
            currentHymn,
            _audioService.isPlaying,
            position: position,
            duration: _audioService.duration,
          );
        }
      }
    });

    // Listen to playlist changes to update button states
    ever(_audioService.playlistChangeNotifier, (int _) {
      if (_isForeground) {
        final currentHymn = _audioService.currentHymn;
        if (currentHymn != null) {
          // Update notification to reflect current playlist state
          NotificationService.updateAudioPlayerProgress(
            currentHymn,
            _audioService.isPlaying,
            position: _audioService.currentPosition,
            duration: _audioService.duration,
          );
        }
      }
    });
  }

  void _startForegroundService() {
    if (kDebugMode) {
      print('AudioForegroundService: Starting foreground service');
    }
    _isForeground = true;
  }

  void _stopForegroundService() {
    if (kDebugMode) {
      print('AudioForegroundService: Stopping foreground service');
    }
    _isForeground = false;
    _notificationUpdateTimer?.cancel();
    _notificationUpdateTimer = null;
    NotificationService.hideAudioPlayerNotification();
  }

  /// Update notification when hymn changes
  void updateNotification(Hymn? hymn, bool isPlaying) {
    if (_isForeground && hymn != null) {
      NotificationService.updateAudioPlayerProgress(hymn, isPlaying);
    }
  }

  @override
  void onClose() {
    _stopForegroundService();
    super.onClose();
  }
}
