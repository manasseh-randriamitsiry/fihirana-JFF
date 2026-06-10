import 'dart:async';
import 'package:just_audio/just_audio.dart';

import 'package:fihirana/features/hymn/domain/entities/hymn.dart';

abstract class IAudioService {
  // Playback control
  Future<void> playHymn(Hymn hymn, {String? customAudioUrl});
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> stopCurrentAndPlayNew(Hymn newHymn);
  Future<void> seekTo(Duration position);
  Future<void> playNext();
  Future<void> playPrevious();
  Future<void> shuffle();
  Future<void> setRepeat(bool enabled);

  // Playlist management
  void setPlaylist(List<Hymn> playlist, int initialIndex);

  // Audio file management
  Future<bool> checkAudioFileExists(String hymnId);
  Future<Map<String, bool>> checkAudioFilesExist(List<String> hymnIds);
  Future<bool> downloadAudioForHymn(Hymn hymn, {Function(double)? onProgress});
  bool hasLocalAudio(String hymnId);
  Future<bool> isAudioAvailableLocally(String hymnId);
  Future<void> deleteLocalAudio(String hymnId);
  Future<void> clearAllLocalAudio();
  Future<Set<String>> getLocalHymnIds();

  // Recording playback
  Future<void> playRecording(dynamic recording);

  // Cache management
  Future<void> preloadCommonHymns(List<String> hymnIds);
  Future<void> clearExpiredCache();
  Future<void> clearAllCache();
  Future<Map<String, dynamic>> getCacheStats();
  Future<Map<String, dynamic>> getLocalAudioStats();

  // State queries
  bool isHymnPlaying(String hymnId);
  void refreshPlayingState();

  // Getters for streams and state
  Stream<Duration?> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<bool> get playingStream;
  Stream<ProcessingState> get processingStateStream;
  Stream<LoopMode> get loopModeStream;
  Stream<int?> get currentIndexStream;
  Stream<SequenceState?> get sequenceStateStream;
  Stream<PlayerState> get playerStateStream;

  AudioPlayer get player;
  bool get isPlaying;
  Duration get position;
  Duration? get duration;
  int? get currentIndex;

  // Additional state getters for repository
  Hymn? get currentHymn;
  Duration? get currentPosition;
  List<Hymn> get playlist;
  int get currentPlaylistIndex;
  bool get isShuffled;
  bool get isRepeatEnabled;
  bool get hasPlaylist;
  int get playlistLength;

  // Cleanup
  void dispose();
}
