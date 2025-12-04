import 'dart:async';
import 'package:fihirana/features/audio/domain/entities/audio_track.dart';
import 'package:fihirana/features/audio/domain/entities/audio_player_state.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';

abstract class AudioRepository {
  // Player control methods
  Future<void> playHymn(Hymn hymn, {String? customAudioUrl});
  Future<void> playTrack(AudioTrack track);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> seekTo(Duration position);

  // Playlist management
  Future<void> setPlaylist(List<Hymn> playlist, int initialIndex);
  Future<void> playNext();
  Future<void> playPrevious();
  Future<void> shuffle();
  Future<void> setRepeat(bool enabled);

  // Audio availability and caching
  Future<bool> checkAudioFileExists(String hymnId);
  Future<Map<String, bool>> checkAudioFilesExist(List<String> hymnIds);
  Future<bool> isAudioAvailableLocally(String hymnId);
  Future<void> downloadAudioForHymn(Hymn hymn, {Function(double)? onProgress});
  Future<void> deleteLocalAudio(String hymnId);
  Future<void> clearAllLocalAudio();
  Future<Set<String>> getLocalHymnIds();

  // Recording playback
  Future<void> playRecording(dynamic recording);

  // Audio metadata
  Future<int> getAudioFileDuration(String filePath);
  Future<int> getAudioUrlDuration(String url);

  // State streams
  Stream<AudioPlayerState> get playerStateStream;
  Stream<Duration> get positionStream;
  Stream<Duration> get durationStream;

  // Current state getters
  AudioPlayerState get currentState;
  Hymn? get currentHymn;
  bool get isPlaying;
  Duration? get currentPosition;
  Duration? get duration;
  bool get hasPlaylist;
  int get currentPlaylistIndex;
  int get playlistLength;

  // Cache management
  Future<void> preloadCommonHymns(List<String> hymnIds);
  Future<void> clearExpiredCache();
  Future<void> clearAllCache();
  Future<Map<String, dynamic>> getCacheStats();
  Future<Map<String, dynamic>> getLocalAudioStats();
}