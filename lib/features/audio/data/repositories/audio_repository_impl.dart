import 'dart:async';
import 'package:fihirana/features/audio/domain/entities/audio_track.dart';
import 'package:fihirana/features/audio/domain/entities/audio_player_state.dart';
import 'package:fihirana/features/audio/domain/repositories/audio_repository.dart';
import 'package:fihirana/features/audio/data/services/audio_service.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';

class AudioRepositoryImpl implements AudioRepository {
  final AudioService _audioService;

  AudioRepositoryImpl(this._audioService);

  @override
  Future<void> playHymn(Hymn hymn, {String? customAudioUrl}) {
    return _audioService.playHymn(hymn, customAudioUrl: customAudioUrl);
  }

  @override
  Future<void> playTrack(AudioTrack track) {
    // Convert AudioTrack to Hymn for compatibility with existing service
    final hymn = Hymn(
      id: track.id,
      hymnNumber: track.id,
      title: track.title,
      verses: [],
      createdAt: track.createdAt,
      createdBy: track.artist ?? '',
    );
    return _audioService.playHymn(hymn, customAudioUrl: track.audioUrl ?? track.localPath);
  }

  @override
  Future<void> pause() {
    return _audioService.pause();
  }

  @override
  Future<void> resume() {
    return _audioService.resume();
  }

  @override
  Future<void> stop() {
    return _audioService.stop();
  }

  @override
  Future<void> seekTo(Duration position) {
    return _audioService.seekTo(position);
  }

  @override
  Future<void> setPlaylist(List<Hymn> playlist, int initialIndex) async {
    _audioService.setPlaylist(playlist, initialIndex);
  }

  @override
  Future<void> playNext() {
    return _audioService.playNext();
  }

  @override
  Future<void> playPrevious() {
    return _audioService.playPrevious();
  }

  @override
  Future<void> shuffle() {
    return _audioService.shuffle();
  }

  @override
  Future<void> setRepeat(bool enabled) {
    return _audioService.setRepeat(enabled);
  }

  @override
  Future<bool> checkAudioFileExists(String hymnId) {
    return _audioService.checkAudioFileExists(hymnId);
  }

  @override
  Future<Map<String, bool>> checkAudioFilesExist(List<String> hymnIds) {
    return _audioService.checkAudioFilesExist(hymnIds);
  }

  @override
  Future<bool> isAudioAvailableLocally(String hymnId) {
    return _audioService.isAudioAvailableLocally(hymnId);
  }

  @override
  Future<void> downloadAudioForHymn(Hymn hymn, {Function(double)? onProgress}) {
    return _audioService.downloadAudioForHymn(hymn, onProgress: onProgress);
  }

  @override
  Future<void> deleteLocalAudio(String hymnId) {
    return _audioService.deleteLocalAudio(hymnId);
  }

  @override
  Future<void> clearAllLocalAudio() {
    return _audioService.clearAllLocalAudio();
  }

  @override
  Future<Set<String>> getLocalHymnIds() {
    return _audioService.getLocalHymnIds();
  }

  @override
  Future<void> playRecording(dynamic recording) {
    return _audioService.playRecording(recording);
  }

  @override
  Future<int> getAudioFileDuration(String filePath) {
    return AudioService.getAudioFileDuration(filePath);
  }

  @override
  Future<int> getAudioUrlDuration(String url) {
    return AudioService.getAudioUrlDuration(url);
  }

  @override
  Stream<AudioPlayerState> get playerStateStream {
    return _audioService.playerStateStream.map((playerState) {
      return AudioPlayerState(
        currentHymn: _audioService.currentHymn,
        isPlaying: playerState.playing,
        isLoading: false, // Basic implementation - can be enhanced later
        position: _audioService.currentPosition ?? Duration.zero,
        duration: _audioService.duration ?? Duration.zero,
        error: null, // Basic implementation - can be enhanced later
        playlist: _audioService.playlist,
        currentPlaylistIndex: _audioService.currentPlaylistIndex,
        isShuffled: _audioService.isShuffled,
        isRepeating: _audioService.isRepeatEnabled,
      );
    });
  }

  @override
  Stream<Duration> get positionStream {
    return _audioService.positionStream.map((position) => position ?? Duration.zero);
  }

  @override
  Stream<Duration> get durationStream {
    return _audioService.durationStream.map((duration) => duration ?? Duration.zero);
  }

  @override
  AudioPlayerState get currentState {
    return AudioPlayerState(
      currentHymn: _audioService.currentHymn,
      isPlaying: _audioService.isPlaying,
      isLoading: false, // Basic implementation
      position: _audioService.currentPosition ?? Duration.zero,
      duration: _audioService.duration ?? Duration.zero,
      error: null, // Basic implementation
      playlist: _audioService.playlist,
      currentPlaylistIndex: _audioService.currentPlaylistIndex,
      isShuffled: _audioService.isShuffled,
      isRepeating: _audioService.isRepeatEnabled,
    );
  }

  @override
  Hymn? get currentHymn => _audioService.currentHymn;

  @override
  bool get isPlaying => _audioService.isPlaying;

  @override
  Duration? get currentPosition => _audioService.currentPosition;

  @override
  Duration? get duration => _audioService.duration;

  @override
  bool get hasPlaylist => _audioService.hasPlaylist;

  @override
  int get currentPlaylistIndex => _audioService.currentPlaylistIndex;

  @override
  int get playlistLength => _audioService.playlistLength;

  @override
  Future<void> preloadCommonHymns(List<String> hymnIds) {
    return _audioService.preloadCommonHymns(hymnIds);
  }

  @override
  Future<void> clearExpiredCache() {
    return _audioService.clearExpiredCache();
  }

  @override
  Future<void> clearAllCache() {
    return _audioService.clearAllCache();
  }

  @override
  Future<Map<String, dynamic>> getCacheStats() {
    return _audioService.getCacheStats();
  }

  @override
  Future<Map<String, dynamic>> getLocalAudioStats() {
    return _audioService.getLocalAudioStats();
  }
}