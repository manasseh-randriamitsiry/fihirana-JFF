import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'audio_service.dart';
import 'package:fihirana/core/utils/notification_service.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';

/// Service to manage audio player notifications in foreground
class AudioForegroundService extends GetxService {
  static const _progressNotificationInterval = Duration(seconds: 15);

  static AudioForegroundService? _instance;
  bool _isForeground = false;
  Duration? _lastNotifiedPosition;
  late AudioService _audioService;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;

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
        _lastNotifiedPosition = null;
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
    _playerStateSubscription = _audioService.playerStateStream.listen((state) {
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

    // Keep media controls stable while the user targets them. Recreating the
    // notification on every position tick replaces its actions before a tap
    // can be handled reliably. State and track changes still update at once.
    _positionSubscription = _audioService.positionStream.listen((position) {
      if (_isForeground && position != null) {
        final lastPosition = _lastNotifiedPosition;
        final hasMovedBackwards =
            lastPosition != null && position < lastPosition;
        final isProgressUpdateDue = lastPosition == null ||
            position - lastPosition >= _progressNotificationInterval;

        if (!hasMovedBackwards && !isProgressUpdateDue) return;
        _lastNotifiedPosition = position;

        final currentHymn = _audioService.currentHymn;
        if (currentHymn != null) {
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
    _lastNotifiedPosition = null;
  }

  void _stopForegroundService() {
    if (kDebugMode) {
      print('AudioForegroundService: Stopping foreground service');
    }
    _isForeground = false;
    _lastNotifiedPosition = null;
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
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _stopForegroundService();
    super.onClose();
  }
}
