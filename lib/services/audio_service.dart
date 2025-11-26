import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart'; // For Color
import '../models/hymn.dart';
import 'audio_cache_service.dart';
import 'audio_file_mapping.dart';
import 'local_audio_service.dart';
import 'google_drive_service.dart';

class AudioService {
  static AudioService? _instance;
  static AudioService get instance {
    _instance ??= AudioService._internal();
    return _instance!;
  }

  factory AudioService() => instance;
  AudioService._internal() {
    _initializePlayerStateListener();
    _initializePlayerOnStartup();
  }

  void _initializePlayerOnStartup() {
    // Check if player is in a bad state on startup and reset it
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        final state = _player.playerState;
        if (state.processingState == ProcessingState.idle && 
            _currentPlayingHymnId.value.isNotEmpty) {
          if (kDebugMode) {
            print('AudioService: Detected bad state on startup, resetting');
          }
          _currentPlayingHymnId.value = '';
          _currentHymn = null;
        }
      } catch (e) {
        if (kDebugMode) {
          print('AudioService: Error checking startup state: $e');
        }
      }
    });
  }

  void _initializePlayerStateListener() {
    // Listen to player state changes to properly manage playing state
    _player.playerStateStream.listen((state) {
      if (kDebugMode) {
        print(
            'AudioService: Player state changed - playing: ${state.playing}, processingState: ${state.processingState}');
      }
      
      // Handle completion state
      if (state.processingState == ProcessingState.completed) {
        _currentPlayingHymnId.value = '';
        _currentHymn = null;
      }
    });

    // Listen to player errors via playerStateStream
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.idle && 
          _currentPlayingHymnId.value.isNotEmpty) {
        if (kDebugMode) {
          print('AudioService: Player entered idle state, likely due to error');
        }
        _currentPlayingHymnId.value = '';
        _currentHymn = null;
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
  final RxInt _playlistChangeNotifier = 0.obs; // Used to trigger playlist updates

  AudioPlayer get player => _player;
  Hymn? get currentHymn => _currentHymn;

  // ... (keep existing methods)

void setPlaylist(List<Hymn> playlist, int initialIndex) {
    _playlist = playlist;
    _currentPlaylistIndex = initialIndex;
    _playlistChangeNotifier.value++; // Trigger playlist change notification
    if (kDebugMode) {
      print(
          'AudioService: Playlist set with ${_playlist.length} hymns, starting at $initialIndex');
    }
  }

  Future<void> playNext() async {
    if (_playlist.isEmpty || _currentPlaylistIndex == -1) return;

    if (_currentPlaylistIndex < _playlist.length - 1) {
      _currentPlaylistIndex++;
      _playlistChangeNotifier.value++; // Trigger playlist change notification
      final nextHymn = _playlist[_currentPlaylistIndex];
      await playHymn(nextHymn);
    } else if (_playlist.isNotEmpty && _currentPlaylistIndex == _playlist.length - 1) {
      // Loop back to first hymn if at end
      _currentPlaylistIndex = 0;
      _playlistChangeNotifier.value++;
      final firstHymn = _playlist[_currentPlaylistIndex];
      await playHymn(firstHymn);
    }
  }

  Future<void> playPrevious() async {
    if (_playlist.isEmpty || _currentPlaylistIndex == -1) return;

    if (_currentPlaylistIndex > 0) {
      _currentPlaylistIndex--;
      _playlistChangeNotifier.value++; // Trigger playlist change notification
      final prevHymn = _playlist[_currentPlaylistIndex];
      await playHymn(prevHymn);
    } else if (_playlist.isNotEmpty && _currentPlaylistIndex == 0) {
      // Loop to last hymn if at first
      _currentPlaylistIndex = _playlist.length - 1;
      _playlistChangeNotifier.value++;
      final lastHymn = _playlist[_currentPlaylistIndex];
      await playHymn(lastHymn);
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

  Future<void> playHymn(Hymn hymn, {String? customAudioUrl}) async {
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

    if (customAudioUrl != null) {
      // Use provided URL (could be local path or remote URL)
      audioUrl = customAudioUrl;
      // Check if it's a remote URL
      if (audioUrl.startsWith('http')) {
        isLocalFile = false;
        if (kDebugMode) {
          print('AudioService: Using provided remote audio URL: $audioUrl');
        }
      } else {
        isLocalFile = true;
        if (kDebugMode) {
          print('AudioService: Using provided local audio file: $audioUrl');
        }
      }
    } else if (localAudioPath != null) {
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
    } on PlayerException catch (e) {
      _currentPlayingHymnId.value = '';
      if (kDebugMode) {
        print('AudioService: PlayerException playing hymn ${hymn.id}: ${e.code} - ${e.message}');
      }

      // Provide more user-friendly error messages
      String userMessage = 'Failed to play audio';
      final message = e.message ?? '';
      if (message.toLowerCase().contains('network') || 
          message.toLowerCase().contains('connection')) {
        userMessage = 'Network connection error. Please check your internet connection.';
      } else if (message.toLowerCase().contains('not found') ||
          message.toLowerCase().contains('404')) {
        userMessage = 'Audio file not found for hymn ${hymn.id}';
      } else if (message.toLowerCase().contains('format') ||
          message.toLowerCase().contains('corrupted')) {
        userMessage = 'Audio format not supported or file corrupted for hymn ${hymn.id}';
      } else {
        userMessage = 'Failed to play hymn ${hymn.id}: $message';
      }

      throw Exception(userMessage);
    } on PlayerInterruptedException catch (e) {
      _currentPlayingHymnId.value = '';
      if (kDebugMode) {
        print('AudioService: PlayerInterruptedException for hymn ${hymn.id}: ${e.message}');
      }
      // Don't throw for interruptions as this is expected behavior
    } catch (e) {
      _currentPlayingHymnId.value = '';
      if (kDebugMode) {
        print('AudioService: Unexpected error playing hymn ${hymn.id}: $e');
      }

      throw Exception('Unexpected error playing hymn ${hymn.id}: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      if (kDebugMode) {
        print('AudioService: Error pausing player: $e');
      }
    }
  }

  Future<void> resume() async {
    try {
      await _player.play();
    } catch (e) {
      if (kDebugMode) {
        print('AudioService: Error resuming player: $e');
      }
    }
  }

  Future<void> stop() async {
    if (kDebugMode) {
      print('AudioService: Stopping playback');
    }
    try {
      await _player.stop();
    } catch (e) {
      if (kDebugMode) {
        print('AudioService: Error stopping player: $e');
      }
    }
    _currentHymn = null;
    _currentPlayingHymnId.value = '';
  }

  Future<void> stopCurrentAndPlayNew(Hymn newHymn) async {
    if (kDebugMode) {
      print(
          'AudioService: Stopping current and playing new hymn ${newHymn.id}');
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
    } on PlayerException catch (e) {
      if (kDebugMode) {
        print('AudioService: Seek error - ${e.code}: ${e.message}');
      }
      final message = e.message ?? 'Unknown error';
      throw Exception('Failed to seek audio: $message');
    } catch (e) {
      if (kDebugMode) {
        print('AudioService: Unexpected seek error: $e');
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

  // Getters for playlist status
  bool get hasPlaylist => _playlist.isNotEmpty;
  int get currentPlaylistIndex => _currentPlaylistIndex;
  int get playlistLength => _playlist.length;
  bool get canGoNext => hasPlaylist && _currentPlaylistIndex < _playlist.length - 1;
  bool get canGoPrevious => hasPlaylist && _currentPlaylistIndex > 0;
  RxInt get playlistChangeNotifier => _playlistChangeNotifier;

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
      audioUrl ??=
          'https://raw.githubusercontent.com/manasseh-randriamitsiry/Fihirana-audio/main/${hymn.id}.mp3';
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

  // Helper to play a user recording
  Future<void> playRecording(dynamic recording) async {
    // We use dynamic here to avoid circular imports if UserRecording is in a different package
    // but ideally we should import UserRecording.
    // Assuming recording has: id, title, hymnId, filePath

    final hymn = Hymn(
      id: recording.id,
      hymnNumber: recording.hymnId,
      title: recording.title,
      verses: [],
      createdAt: recording.createdAt,
      createdBy: 'User',
    );

    String? audioUrl;
    String targetPath = recording.filePath;

    // PRIORITY 1: Check if recording has a public link (for public recordings - no auth needed)
    if (recording.publicLink != null && recording.publicLink!.isNotEmpty) {
      audioUrl = recording.publicLink;
      if (kDebugMode) {
        print('AudioService: Streaming public recording from: $audioUrl');
      }
    }
    // PRIORITY 2: Check if local file exists
    else if (targetPath.isNotEmpty) {
      final file = File(targetPath);
      if (await file.exists()) {
        audioUrl = targetPath;
      }
    } else {
      // Generate a path if one doesn't exist
      final stats = await _localAudioService.getStorageStats();
      final dir = stats['directory'] as String;
      // Default to .m4a as it's common for mobile recordings, or .mp3
      targetPath = path.join(dir, 'recording_${recording.id}.m4a');
      if (kDebugMode) {
        print('AudioService: Generated target path: $targetPath');
      }
    }

    // PRIORITY 3: If no local file and no public link, try to download from Drive (private recordings)
    if (audioUrl == null && recording.driveFileId != null) {
      if (kDebugMode) {
        print(
            'AudioService: Private recording - attempting download from Drive...');
      }

      // Show loading indicator
      Get.snackbar(
        'Downloading Audio',
        'Fetching recording from Google Drive...',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      try {
        final driveService = GoogleDriveService();

        // Ensure user is signed in
        if (!driveService.isSignedIn) {
          await driveService.signInSilently();
        }

        if (driveService.isSignedIn) {
          final downloadedFile = await driveService.downloadFile(
            recording.driveFileId!,
            targetPath, // Save to the expected local path
          );

          if (downloadedFile != null && await downloadedFile.exists()) {
            audioUrl = downloadedFile.path;
            if (kDebugMode) {
              print('AudioService: Download successful: $audioUrl');
            }
          } else {
            throw Exception('Download failed');
          }
        } else {
          throw Exception('Sign-in required to play Drive recordings');
        }
      } catch (e) {
        if (kDebugMode) {
          print('AudioService: Error downloading from Drive: $e');
        }
        Get.snackbar(
          'Error',
          'Failed to download recording from Drive. Please check your connection.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFFFCDD2),
          colorText: const Color(0xFFC62828),
        );
        return; // Stop playback attempt
      }
    }

    if (audioUrl != null) {
      await playHymn(hymn, customAudioUrl: audioUrl);
    } else {
      Get.snackbar(
        'Error',
        'Audio file not found locally or on Drive.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
