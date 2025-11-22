import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:get/get.dart';
import '../models/hymn.dart';
import 'audio_cache_service.dart';
import 'audio_file_mapping.dart';
import 'local_audio_service.dart';

class AudioService {
  static AudioService? _instance;
  static AudioService get instance {
    _instance ??= AudioService._internal();
    return _instance!;
  }

  factory AudioService() => instance;
  AudioService._internal() {
    _initializePlayerStateListener();
  }

  void _initializePlayerStateListener() {
    // Listen to player state changes to properly manage playing state
    _player.playerStateStream.listen((state) {
      if (kDebugMode) {
        print(
          'AudioService: Player state changed - playing: ${state.playing}, processingState: ${state.processingState}');
      }
    });
  }

  final AudioPlayer _player = AudioPlayer(
    audioPipeline: AudioPipeline(
      androidAudioEffects: [],
    ),
  );
  Hymn? _currentHymn;
  List<Hymn> _playlist = [];
  int _currentPlaylistIndex = -1;

  final AudioCacheService _cacheService = AudioCacheService();
  final LocalAudioService _localAudioService = LocalAudioService();
  final RxString _currentPlayingHymnId = ''.obs;

  AudioPlayer get player => _player;
  Hymn? get currentHymn => _currentHymn;

  // ... (keep existing methods)

  void setPlaylist(List<Hymn> playlist, int initialIndex) {
    _playlist = playlist;
    _currentPlaylistIndex = initialIndex;
    if (kDebugMode) {
      print(
        'AudioService: Playlist set with ${_playlist.length} hymns, starting at $initialIndex');
    }
  }

  Future<void> playNext() async {
    if (_playlist.isEmpty || _currentPlaylistIndex == -1) return;

    if (_currentPlaylistIndex < _playlist.length - 1) {
      _currentPlaylistIndex++;
      final nextHymn = _playlist[_currentPlaylistIndex];
      await playHymn(nextHymn);
    }
  }

  Future<void> playPrevious() async {
    if (_playlist.isEmpty || _currentPlaylistIndex == -1) return;

    if (_currentPlaylistIndex > 0) {
      _currentPlaylistIndex--;
      final prevHymn = _playlist[_currentPlaylistIndex];
      await playHymn(prevHymn);
    }
  }

  Future<bool> checkAudioFileExists(String hymnId) async {
    // Use the new cache service
    return await _cacheService.checkAudioExists(hymnId);
  }

  // Batch check for multiple hymns (much more efficient with cache)
  Future<Map<String, bool>> checkAudioFilesExist(List<String> hymnIds) async {
    // Use the new cache service for efficient batch checking
    return await _cacheService.checkMultipleAudioExists(hymnIds);
  }

  Future<void> playHymn(Hymn hymn) async {
    if (kDebugMode) {
      print('AudioService: Starting to play hymn ${hymn.id}');
    }

    // Stop current playback if different hymn is playing
    if (_currentPlayingHymnId.value.isNotEmpty &&
        _currentPlayingHymnId.value != hymn.id) {
      await _player.stop();
      await Future.delayed(
          const Duration(milliseconds: 100)); // Brief pause for cleanup
    }

    _currentHymn = hymn;

    // Update playlist index if this hymn is in the current playlist
    if (_playlist.isNotEmpty) {
      final index = _playlist.indexWhere((h) => h.id == hymn.id);
      if (index != -1) {
        _currentPlaylistIndex = index;
      }
    }

    // Initialize local audio service
    await _localAudioService.initialize();

    // Check if audio exists locally first
    final localAudioPath = _localAudioService.getLocalAudioPath(hymn.id);
    String audioUrl;
    bool isLocalFile = false;

    if (localAudioPath != null) {
      // Use local file
      audioUrl = localAudioPath;
      isLocalFile = true;
      if (kDebugMode) {
        print('AudioService: Using local audio file: $localAudioPath');
      }
    } else {
      // Get the correct audio URL using the mapping
      final audioMapping = AudioFileMapping();
      audioUrl = audioMapping.getAudioUrl(hymn.id) ??
          'https://raw.githubusercontent.com/manasseh-randriamitsiry/Fihirana-audio/main/${hymn.id}.mp3';

      // If mapping is expired, try to update it
      if (audioMapping.isCacheExpired()) {
        await audioMapping.updateAudioFileMapping();
        audioUrl = audioMapping.getAudioUrl(hymn.id) ?? audioUrl;
      }

      if (kDebugMode) {
        print('AudioService: Using remote audio URL: $audioUrl');
      }
    }

    try {
      // Use AudioSource with proper buffering for smooth seeking
      // This pre-buffers the audio for better performance
      AudioSource audioSource;

      if (isLocalFile) {
        // Use local file
        audioSource = AudioSource.uri(
          Uri.file(audioUrl),
          tag: hymn.id, // Tag for identification
        );
        if (kDebugMode) {
          print('AudioService: Created local audio source for ${hymn.id}');
        }
      } else {
        // Use remote URL
        audioSource = AudioSource.uri(
          Uri.parse(audioUrl),
          tag: hymn.id, // Tag for identification
        );
        if (kDebugMode) {
          print('AudioService: Created remote audio source for ${hymn.id}');
        }
      }

      // Set the audio source with buffering
      await _player.setAudioSource(
        audioSource,
        preload: true, // Preload the audio for faster seeking
      );

      _currentPlayingHymnId.value = hymn.id;
      if (kDebugMode) {
        print('AudioService: Audio source set, playing hymn ${hymn.id}');
      }

      await _player.play();
      if (kDebugMode) {
        print('AudioService: Started playing hymn ${hymn.id}');
      }
    } catch (e) {
      _currentPlayingHymnId.value = '';
      if (kDebugMode) {
        print('AudioService: Error playing hymn ${hymn.id}: $e');
      }

      // Provide more user-friendly error messages
      String userMessage = 'Failed to play audio';
      if (e.toString().contains('Network') ||
          e.toString().contains('timeout')) {
        userMessage =
            'Network connection error. Please check your internet connection.';
      } else if (e.toString().contains('not found')) {
        userMessage = 'Audio file not found for hymn ${hymn.id}';
      }

      throw Exception(userMessage);
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> stop() async {
    if (kDebugMode) {
      print('AudioService: Stopping playback');
    }
    await _player.stop();
    _currentHymn = null;
    _currentPlayingHymnId.value = '';
  }

  Future<void> stopCurrentAndPlayNew(Hymn newHymn) async {
    if (kDebugMode) {
      print('AudioService: Stopping current and playing new hymn ${newHymn.id}');
    }

    // Stop current playback if any
    if (_currentPlayingHymnId.value.isNotEmpty) {
      await _player.stop();
      await Future.delayed(
          const Duration(milliseconds: 200)); // Allow for cleanup
    }

    // Play new hymn
    await playHymn(newHymn);
  }

  Future<void> seekTo(Duration position) async {
    try {
      if (kDebugMode) {
        print('AudioService: Seeking to ${position.inMilliseconds}ms');
      }
      await _player.seek(position);
    } catch (e) {
      if (kDebugMode) {
        print('AudioService: Seek error: $e');
      }
      throw Exception('Failed to seek audio: $e');
    }
  }

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<SequenceState?> get sequenceStateStream => _player.sequenceStateStream;

  bool get isPlaying => _player.playing;
  Duration? get currentPosition => _player.position;
  Duration? get duration => _player.duration;

  void dispose() {
    _player.dispose();
    _currentPlayingHymnId.value = '';
    _cacheService.close();
  }

  // Getters for reactive state
  String get currentPlayingHymnId => _currentPlayingHymnId.value;
  RxString get currentPlayingHymnIdRx => _currentPlayingHymnId;

  bool isHymnPlaying(String hymnId) {
    final isCurrentHymn = _currentPlayingHymnId.value == hymnId;
    final isActuallyPlaying = isPlaying;
    final result = isCurrentHymn && isActuallyPlaying;

    if (kDebugMode) {
      print(
        'AudioService: isHymnPlaying($hymnId) = $result (current: ${_currentPlayingHymnId.value}, isPlaying: $isActuallyPlaying)');
    }
    return result;
  }

  // Force refresh the current playing state (useful for UI synchronization)
  void refreshPlayingState() {
    final currentId = _currentPlayingHymnId.value;
    final currentlyPlaying = isPlaying;

    if (kDebugMode) {
      print(
        'AudioService: Refresh state - ID: $currentId, Playing: $currentlyPlaying');
    }

    // If we think something is playing but it's not, clear the state
    if (currentId.isNotEmpty && !currentlyPlaying) {
      _currentPlayingHymnId.value = '';
      _currentHymn = null;
    }
  }

  // Cache management methods
  Future<void> preloadCommonHymns(List<String> hymnIds) async {
    await _cacheService.preloadCommonHymns(hymnIds);
  }

  Future<void> clearExpiredCache() async {
    await _cacheService.clearExpiredCache();
  }

  Future<void> clearAllCache() async {
    await _cacheService.clearAllCache();
  }

  Future<Map<String, dynamic>> getCacheStats() async {
    return await _cacheService.getCacheStats();
  }

  // Local audio management methods
  Future<bool> downloadAudioForHymn(Hymn hymn,
      {Function(double)? onProgress}) async {
    // Get the correct audio URL
    final audioMapping = AudioFileMapping();
    String? audioUrl = audioMapping.getAudioUrl(hymn.id);

    if (audioUrl == null) {
      if (audioMapping.isCacheExpired()) {
        await audioMapping.updateAudioFileMapping();
        audioUrl = audioMapping.getAudioUrl(hymn.id);
      }
      audioUrl ??= 'https://raw.githubusercontent.com/manasseh-randriamitsiry/Fihirana-audio/main/${hymn.id}.mp3';
    }

    return await _localAudioService.downloadAudio(hymn.id, audioUrl,
        onProgress: onProgress);
  }

  bool hasLocalAudio(String hymnId) {
    return _localAudioService.hasLocalAudio(hymnId);
  }

  Future<bool> isAudioAvailableLocally(String hymnId) async {
    await _localAudioService.initialize();
    return _localAudioService.hasLocalAudio(hymnId);
  }

  Future<Map<String, dynamic>> getLocalAudioStats() async {
    return await _localAudioService.getStorageStats();
  }

  Future<void> deleteLocalAudio(String hymnId) async {
    await _localAudioService.deleteLocalAudio(hymnId);
  }

  Future<void> clearAllLocalAudio() async {
    await _localAudioService.clearAllLocalAudio();
  }

  Future<Set<String>> getLocalHymnIds() async {
    return await _localAudioService.getLocalHymnIds();
  }
}
