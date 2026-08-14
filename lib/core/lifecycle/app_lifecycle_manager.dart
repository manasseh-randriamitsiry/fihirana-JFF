import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fihirana/features/audio/data/services/audio_service.dart';
import 'package:fihirana/core/utils/notification_service.dart';

/// Manages application lifecycle events
class AppLifecycleManager extends WidgetsBindingObserver {
  final AudioService _audioService = AudioService.instance;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // App is in background
        break;
      case AppLifecycleState.detached:
        // App is being closed - cleanup audio
        _cleanupAudioOnAppClose();
        break;
      case AppLifecycleState.resumed:
        // App is in foreground
        break;
      default:
        break;
    }
  }

  /// Cleanup audio when app is closed
  void _cleanupAudioOnAppClose() {
    try {
      // Stop playback immediately
      _audioService.stop();

      // Only clear the audio controls. Scheduled daily verses and other app
      // notifications must survive an audio-player shutdown.
      NotificationService.hideAudioPlayerNotification();

      if (kDebugMode) {
        print(
            'App closing: Aggressively cleaned up audio service and all notifications');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during app close cleanup: $e');
      }
    }
  }

  /// General cleanup method
  void cleanupServices() {
    try {
      // Stop audio playback
      _audioService.stop();

      // Hide only the player notification.
      NotificationService.hideAudioPlayerNotification();

      // Dispose audio service
      _audioService.dispose();

      if (kDebugMode) {
        print('App disposed: Cleaned up all services and notifications');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during cleanup: $e');
      }
    }
  }
}
