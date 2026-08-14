import 'dart:async';

import 'package:audio_service/audio_service.dart' as media;
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart' as just_audio;

import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'audio_service.dart' as app_audio;

/// Bridges the app's single [app_audio.AudioService] to Android's media
/// session. Android owns the notification and dispatches its controls directly
/// to this handler, rather than through independently recreated notifications.
class HymnAudioHandler extends media.BaseAudioHandler with media.SeekHandler {
  HymnAudioHandler(this._audioService) {
    _playerStateSubscription =
        _audioService.playerStateStream.listen(_publishPlaybackState);
    _durationSubscription = _audioService.durationStream.listen((_) {
      _publishMediaItem();
      _publishPlaybackState(_audioService.player.playerState);
    });
    _hymnWorker = ever(_audioService.currentPlayingHymnIdRx, (_) {
      _publishMediaItem();
      _publishPlaybackState(_audioService.player.playerState);
    });
    _playlistWorker = ever(_audioService.playlistChangeNotifier, (_) {
      _publishQueue();
      _publishPlaybackState(_audioService.player.playerState);
    });

    _publishQueue();
    _publishMediaItem();
    _publishPlaybackState(_audioService.player.playerState);
  }

  final app_audio.AudioService _audioService;
  late final Worker _hymnWorker;
  late final Worker _playlistWorker;
  late final StreamSubscription<just_audio.PlayerState>
      _playerStateSubscription;
  late final StreamSubscription<Duration?> _durationSubscription;

  media.MediaItem? _lastMediaItem;

  void synchronize() {
    _publishQueue();
    _publishMediaItem();
    _publishPlaybackState(_audioService.player.playerState);
  }

  media.MediaItem _toMediaItem(Hymn hymn, {Duration? duration}) {
    return media.MediaItem(
      id: hymn.id,
      album: 'Fihirana JFF',
      title: hymn.title,
      artist: 'Hira faha ${hymn.hymnNumber}',
      duration: duration,
    );
  }

  void _publishQueue() {
    queue.add(_audioService.playlist.map(_toMediaItem).toList());
  }

  void _publishMediaItem() {
    final hymn = _audioService.currentHymn;
    if (hymn == null || _audioService.currentPlayingHymnId.isEmpty) {
      _lastMediaItem = null;
      mediaItem.add(null);
      return;
    }

    final item = _toMediaItem(hymn, duration: _audioService.duration);
    if (_lastMediaItem?.id == item.id &&
        _lastMediaItem?.duration == item.duration) {
      return;
    }

    _lastMediaItem = item;
    mediaItem.add(item);
  }

  void _publishPlaybackState(just_audio.PlayerState state) {
    final hasCurrentHymn = _audioService.currentPlayingHymnId.isNotEmpty;
    final isCompleted =
        state.processingState == just_audio.ProcessingState.completed;
    final controls = <media.MediaControl>[
      if (hasCurrentHymn && _audioService.canGoPrevious)
        media.MediaControl.skipToPrevious,
      if (hasCurrentHymn && !isCompleted)
        state.playing ? media.MediaControl.pause : media.MediaControl.play,
      if (hasCurrentHymn && _audioService.canGoNext)
        media.MediaControl.skipToNext,
      if (hasCurrentHymn) media.MediaControl.stop,
    ];

    final compactActionIndices = <int>[];
    for (var index = 0; index < controls.length; index++) {
      final action = controls[index].action;
      if (action == media.MediaAction.skipToPrevious ||
          action == media.MediaAction.play ||
          action == media.MediaAction.pause ||
          action == media.MediaAction.skipToNext) {
        compactActionIndices.add(index);
      }
    }

    playbackState.add(
      media.PlaybackState(
        controls: controls,
        androidCompactActionIndices: compactActionIndices.take(3).toList(),
        systemActions: hasCurrentHymn
            ? const {
                media.MediaAction.seek,
                media.MediaAction.seekBackward,
                media.MediaAction.seekForward,
              }
            : const {},
        // Once playback has stopped or completed, expose an idle session so
        // Android removes stale metadata and controls from System UI.
        processingState: hasCurrentHymn
            ? _toProcessingState(state.processingState)
            : media.AudioProcessingState.idle,
        playing: hasCurrentHymn && state.playing,
        updatePosition: _audioService.position,
        bufferedPosition: _audioService.player.bufferedPosition,
        speed: _audioService.player.speed,
        queueIndex: _audioService.currentPlaylistIndex >= 0
            ? _audioService.currentPlaylistIndex
            : null,
      ),
    );
  }

  media.AudioProcessingState _toProcessingState(
    just_audio.ProcessingState state,
  ) {
    switch (state) {
      case just_audio.ProcessingState.idle:
        return media.AudioProcessingState.idle;
      case just_audio.ProcessingState.loading:
        return media.AudioProcessingState.loading;
      case just_audio.ProcessingState.buffering:
        return media.AudioProcessingState.buffering;
      case just_audio.ProcessingState.ready:
        return media.AudioProcessingState.ready;
      case just_audio.ProcessingState.completed:
        return media.AudioProcessingState.completed;
    }
  }

  @override
  Future<void> play() async {
    unawaited(_audioService.resume());
  }

  @override
  Future<void> pause() async {
    await _audioService.pause();
  }

  @override
  Future<void> stop() async {
    await _audioService.stop();
  }

  @override
  Future<void> skipToNext() async {
    if (_audioService.canGoNext) {
      unawaited(_audioService.playNext());
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_audioService.canGoPrevious) {
      unawaited(_audioService.playPrevious());
    }
  }

  @override
  Future<void> seek(Duration position) {
    return _audioService.seekTo(position);
  }

  @override
  Future<void> fastForward() {
    final duration = _audioService.duration;
    final target = _audioService.position + const Duration(seconds: 10);
    return seek(duration != null && target > duration ? duration : target);
  }

  @override
  Future<void> rewind() {
    final target = _audioService.position - const Duration(seconds: 10);
    return seek(target.isNegative ? Duration.zero : target);
  }

  @override
  Future<void> onTaskRemoved() => stop();

  Future<void> disposeHandler() async {
    _hymnWorker.dispose();
    _playlistWorker.dispose();
    await _playerStateSubscription.cancel();
    await _durationSubscription.cancel();
  }
}

/// Owns the process-wide media session used by Android's notification and
/// lock-screen controls. It is intentionally initialized once at app startup.
class HymnMediaSession {
  static HymnAudioHandler? _handler;
  static Future<void>? _initialization;

  static Future<void> initialize(app_audio.AudioService audioService) {
    return _initialization ??= media.AudioService.init<HymnAudioHandler>(
      builder: () => HymnAudioHandler(audioService),
      config: const media.AudioServiceConfig(
        androidNotificationChannelId: 'fihirana_playback',
        androidNotificationChannelName: 'Lecture musicale',
        androidNotificationChannelDescription:
            'Commandes de lecture des cantiques',
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: false,
        androidShowNotificationBadge: false,
      ),
    ).then((handler) {
      _handler = handler;
    });
  }

  static void synchronize() => _handler?.synchronize();
}
