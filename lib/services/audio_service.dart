import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../models/hymn.dart';
import 'notification_service.dart';
import 'audio_foreground_service.dart';
import 'audio_cache_service.dart';

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
      print('AudioService: Player state changed - playing: ${state.playing}, processingState: ${state.processingState}');
      
      // Update notification through foreground service
      if (_currentHymn != null) {
        final foregroundService = AudioForegroundService.instance;
        foregroundService.updateNotification(_currentHymn, state.playing);
      }
      
      // Only clear the current playing hymn when playback actually stops or completes
      if (state.processingState == ProcessingState.completed ||
          (state.playing == false && _currentPlayingHymnId.value.isNotEmpty && 
           state.processingState != ProcessingState.loading && 
           state.processingState != ProcessingState.buffering)) {
        print('AudioService: Clearing playing hymn ${_currentPlayingHymnId.value}');
        _currentPlayingHymnId.value = '';
      }
    });
  }

  final AudioPlayer _player = AudioPlayer();
  Hymn? _currentHymn;
  final AudioCacheService _cacheService = AudioCacheService();
  final RxString _currentPlayingHymnId = ''.obs;

  AudioPlayer get player => _player;
  Hymn? get currentHymn => _currentHymn;

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
    print('AudioService: Starting to play hymn ${hymn.id}');
    
    // Stop current playback if different hymn is playing
    if (_currentPlayingHymnId.value.isNotEmpty && _currentPlayingHymnId.value != hymn.id) {
      await _player.stop();
      await Future.delayed(const Duration(milliseconds: 100)); // Brief pause for cleanup
    }
    
    _currentHymn = hymn;
    
    final audioUrl = 'https://raw.githubusercontent.com/manasseh-randriamitsiry/Fihirana-audio/main/${hymn.id}.mp3';
    
    try {
      // Set the current playing ID only after successfully setting the URL
      await _player.setUrl(audioUrl);
      _currentPlayingHymnId.value = hymn.id;
      print('AudioService: URL set, playing hymn ${hymn.id}');
      
      await _player.play();
      print('AudioService: Started playing hymn ${hymn.id}');
      
      // Let foreground service handle notification
      final foregroundService = AudioForegroundService.instance;
      foregroundService.updateNotification(hymn, true);
    } catch (e) {
      _currentPlayingHymnId.value = '';
      print('AudioService: Error playing hymn ${hymn.id}: $e');
      final foregroundService = AudioForegroundService.instance;
      foregroundService.updateNotification(null, false);
      throw Exception('Failed to play audio: $e');
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> stop() async {
    print('AudioService: Stopping playback');
    await _player.stop();
    _currentHymn = null;
    _currentPlayingHymnId.value = '';
    final foregroundService = AudioForegroundService.instance;
    foregroundService.updateNotification(null, false);
  }

  Future<void> stopCurrentAndPlayNew(Hymn newHymn) async {
    print('AudioService: Stopping current and playing new hymn ${newHymn.id}');
    
    // Stop current playback if any
    if (_currentPlayingHymnId.value.isNotEmpty) {
      await _player.stop();
      await Future.delayed(const Duration(milliseconds: 200)); // Allow for cleanup
    }
    
    // Play new hymn
    await playHymn(newHymn);
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
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
    
    print('AudioService: isHymnPlaying($hymnId) = $result (current: ${_currentPlayingHymnId.value}, isPlaying: $isActuallyPlaying)');
    return result;
  }

  // Force refresh the current playing state (useful for UI synchronization)
  void refreshPlayingState() {
    final currentId = _currentPlayingHymnId.value;
    final currentlyPlaying = isPlaying;
    
    print('AudioService: Refresh state - ID: $currentId, Playing: $currentlyPlaying');
    
    // If we think something is playing but it's not, clear the state
    if (currentId.isNotEmpty && !currentlyPlaying) {
      _currentPlayingHymnId.value = '';
      _currentHymn = null;
    }
  }

  static Future<void> handleNotificationAction(String action) async {
    final audioService = AudioService.instance;
    
    switch (action) {
      case 'play':
        if (audioService.currentHymn != null) {
          await audioService.resume();
        }
        break;
      case 'pause':
        await audioService.pause();
        break;
      case 'stop':
        await audioService.stop();
        break;
      case 'prev':
        // TODO: Implement previous hymn functionality
        break;
      case 'next':
        // TODO: Implement next hymn functionality
        break;
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
}