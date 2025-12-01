import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

import 'package:just_audio/just_audio.dart';
import 'package:get/get.dart';

import 'package:fihirana/models/hymn.dart';
import 'audio_cache_service.dart';
import 'audio_file_mapping.dart';
import 'local_audio_service.dart';
import 'package:fihirana/services/data/google_drive_service.dart';
import 'package:fihirana/services/core/ui_service.dart';
import 'recording_service.dart';

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

    // Add debugging for position stream
    _player.positionStream.listen((position) {
      if (kDebugMode) {
        print(
            'AudioService: Position stream update: ${position.inMilliseconds}ms');
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
  final RxInt _playlistChangeNotifier =
      0.obs; // Used to trigger playlist updates

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
    } else if (_playlist.isNotEmpty &&
        _currentPlaylistIndex == _playlist.length - 1) {
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
    _currentPlayingHymnId.value = hymn.id; // Ensure reactive update

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
      try {
        await _player
            .setAudioSource(
          audioSource,
          preload: true, // Preload the audio for faster seeking
        )
            .timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            if (kDebugMode) {
              print(
                  'AudioService: Timeout setting audio source for ${hymn.id}');
            }
            throw Exception(
                'Timeout loading audio. Please check your internet connection.');
          },
        );

        if (kDebugMode) {
          print('AudioService: Audio source set, playing hymn ${hymn.id}');
        }

        await _player.play().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            if (kDebugMode) {
              print('AudioService: Timeout starting playback for ${hymn.id}');
            }
            throw Exception('Timeout starting audio playback.');
          },
        );
      } on TimeoutException catch (e) {
        _currentPlayingHymnId.value = '';
        if (kDebugMode) {
          print(
              'AudioService: TimeoutException for hymn ${hymn.id}: ${e.message}');
        }
        throw Exception(
            'Audio loading timeout. Please check your internet connection and try again.');
      }

      // Add debugging to check player state after play
      await Future.delayed(const Duration(milliseconds: 100));
      final stateAfterPlay = _player.playerState;
      if (kDebugMode) {
        print('AudioService: Started playing hymn ${hymn.id}');
        print(
            'AudioService: Player state after play - playing: ${stateAfterPlay.playing}, processingState: ${stateAfterPlay.processingState}');
      }
    } on PlayerException catch (e) {
      _currentPlayingHymnId.value = '';
      if (kDebugMode) {
        print(
            'AudioService: PlayerException playing hymn ${hymn.id}: ${e.code} - ${e.message}');
        print(
            'AudioService: Exception details - URL: $audioUrl, isLocalFile: $isLocalFile');
      }

      // Provide more user-friendly error messages
      String userMessage = 'Failed to play audio';
      final message = e.message ?? '';
      if (message.toLowerCase().contains('network') ||
          message.toLowerCase().contains('connection')) {
        userMessage =
            'Network connection error. Please check your internet connection.';
      } else if (message.toLowerCase().contains('not found') ||
          message.toLowerCase().contains('404')) {
        userMessage = 'Audio file not found for hymn ${hymn.id}';
      } else if (message.toLowerCase().contains('format') ||
          message.toLowerCase().contains('corrupted')) {
        userMessage =
            'Audio format not supported or file corrupted for hymn ${hymn.id}';
      } else if (message.toLowerCase().contains('unsupported') ||
          message.toLowerCase().contains('format')) {
        userMessage =
            'Unsupported audio format or corrupted file for hymn ${hymn.id}';
      } else {
        userMessage = 'Failed to play hymn ${hymn.id}: $message';
      }

      throw Exception(userMessage);
    } on PlayerInterruptedException catch (e) {
      _currentPlayingHymnId.value = '';
      if (kDebugMode) {
        print(
            'AudioService: PlayerInterruptedException for hymn ${hymn.id}: ${e.message}');
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
  Stream<Duration?> get positionStream {
    if (kDebugMode) {
      print('AudioService: Position stream accessed');
    }
    return _player.positionStream;
  }

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
  bool get canGoNext =>
      hasPlaylist && _currentPlaylistIndex < _playlist.length - 1;
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

// PRIORITY 1: Check if recording is public and has a Drive ID (most reliable for streaming)
    if (recording.isPublic && recording.driveFileId != null) {
      // Construct direct download URL which is more reliable than webContentLink
      audioUrl =
          'https://drive.google.com/uc?export=download&id=${recording.driveFileId}';
      if (kDebugMode) {
        print(
            'AudioService: Streaming public recording from generated URL: $audioUrl');
      }
    }
    // Check if recording has a public link (fallback)
    else if (recording.publicLink != null && recording.publicLink!.isNotEmpty) {
      audioUrl = recording.publicLink!;

      // Fix URL format - ensure correct Google Drive download URL format
      if (audioUrl!.contains('drive.google.com')) {
        // Extract file ID from various URL formats
        String? fileId;
        final idMatch = RegExp(r'[?&]id=([^&]+)').firstMatch(audioUrl);
        if (idMatch != null) {
          fileId = idMatch.group(1);
        }

        if (fileId != null) {
          // Create clean, correct URL format
          audioUrl = 'https://drive.google.com/uc?export=download&id=$fileId';
          if (kDebugMode) {
            print('AudioService: Fixed Google Drive URL format to: $audioUrl');
          }
        }
      }

      if (kDebugMode) {
        print(
            'AudioService: Streaming public recording from publicLink: $audioUrl');
        print(
            'AudioService: Recording ID: ${recording.id}, Original link: ${recording.publicLink}');
      }
    }
    // PRIORITY 2: Check if local file exists
    else if (targetPath.isNotEmpty) {
      final file = File(targetPath);
      if (await file.exists()) {
        audioUrl = targetPath;
        if (kDebugMode) {
          print('AudioService: Found local file: $targetPath');
        }
      } else {
        if (kDebugMode) {
          print('AudioService: Local file not found: $targetPath');
        }
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

      // Check if the generated path exists
      final file = File(targetPath);
      if (await file.exists()) {
        audioUrl = targetPath;
        if (kDebugMode) {
          print('AudioService: Found file at generated path: $targetPath');
        }
      }
    }

// PRIORITY 3: If no local file and no public link, try authenticated URL for private recordings
    if (audioUrl == null && recording.driveFileId != null) {
      if (kDebugMode) {
        print(
            'AudioService: Private recording - attempting authenticated URL from Drive...');
        print(
            'AudioService: Recording ID: ${recording.id}, DriveFileId: ${recording.driveFileId}');
      }

      try {
        final driveService = GoogleDriveService();

        // Ensure user is signed in
        if (!driveService.isSignedIn) {
          await driveService.signInSilently();
        }

        if (driveService.isSignedIn) {
          // Try to get authenticated download URL first (faster than downloading)
          final authenticatedUrl = await driveService
              .getAuthenticatedDownloadUrl(recording.driveFileId!);

          if (authenticatedUrl != null) {
            audioUrl = authenticatedUrl;
            if (kDebugMode) {
              print(
                  'AudioService: Using authenticated URL for streaming: $audioUrl');
            }
          } else {
            // Fallback to downloading the file
            if (kDebugMode) {
              print(
                  'AudioService: Authenticated URL failed, falling back to download...');
            }

            // Show loading indicator for download
            UIService.showAudioDownloadingSnackBar();

            // Ensure target path has correct extension
            String finalTargetPath = targetPath;
            if (!finalTargetPath.toLowerCase().endsWith('.m4a') &&
                !finalTargetPath.toLowerCase().endsWith('.mp3') &&
                !finalTargetPath.toLowerCase().endsWith('.wav')) {
              finalTargetPath = '$finalTargetPath.m4a'; // Default to .m4a
              if (kDebugMode) {
                print('AudioService: Updated target path to: $finalTargetPath');
              }
            }

            final downloadedFile = await driveService.downloadFile(
              recording.driveFileId!,
              finalTargetPath, // Save to the expected local path
            );

            if (downloadedFile != null && await downloadedFile.exists()) {
              final fileSize = await downloadedFile.length();
              if (kDebugMode) {
                print('AudioService: Download successful: $audioUrl');
                print('AudioService: File size: $fileSize bytes');
              }

              // Validate file is not empty
              if (fileSize > 0) {
                audioUrl = downloadedFile.path;
              } else {
                // Try alternative approach - maybe the file was corrupted during download
                if (kDebugMode) {
                  print(
                      'AudioService: Downloaded file is empty, trying alternative approach...');
                }

                // Try with a different filename
                final alternativePath =
                    finalTargetPath.replaceAll('.m4a', '_alt.m4a');
                final altDownloadedFile = await driveService.downloadFile(
                  recording.driveFileId!,
                  alternativePath,
                );

                if (altDownloadedFile != null &&
                    await altDownloadedFile.exists()) {
                  final altFileSize = await altDownloadedFile.length();
                  if (altFileSize > 0) {
                    audioUrl = altDownloadedFile.path;
                    if (kDebugMode) {
                      print(
                          'AudioService: Alternative download successful: $audioUrl');
                      print(
                          'AudioService: Alternative file size: $altFileSize bytes');
                    }
                  } else {
                    throw Exception(
                        'Both download attempts resulted in empty files');
                  }
                } else {
                  throw Exception(
                      'Download failed - both attempts resulted in empty files');
                }
              }
            } else {
              throw Exception(
                  'Download failed - file not found after download');
            }
          }
        } else {
          throw Exception('Sign-in required to play Drive recordings');
        }
      } catch (e) {
        if (kDebugMode) {
          print(
              'AudioService: Error accessing private recording from Drive: $e');
          print('AudioService: Error type: ${e.runtimeType}');
        }

        String errorMessage = 'Failed to access recording from Drive.';
        if (e.toString().contains('Google Docs format')) {
          errorMessage =
              'Recording is stored in incompatible Google Docs format. Please re-upload the original audio file.';
        } else if (e.toString().contains('403') ||
            e.toString().contains('permission')) {
          errorMessage =
              'Permission denied accessing Drive file. Please check file sharing settings.';
        } else if (e.toString().contains('network') ||
            e.toString().contains('connection')) {
          errorMessage =
              'Network error accessing Drive. Please check your internet connection.';
        } else if (e.toString().contains('export') ||
            e.toString().contains('format')) {
          errorMessage =
              'Recording format issue. The file may need to be re-uploaded in a compatible audio format.';
        } else {
          errorMessage = 'Drive access error: ${e.toString()}';
        }

        UIService.showAudioDriveErrorSnackBar(errorMessage);
        return; // Stop playback attempt
      }
    }

    if (audioUrl != null) {
      try {
        if (kDebugMode) {
          print(
              'AudioService: Attempting to play recording with URL: $audioUrl');
          print(
              'AudioService: URL type: ${audioUrl.startsWith('http') ? 'Remote' : 'Local'}');
        }
        await playHymn(hymn, customAudioUrl: audioUrl);
      } catch (e) {
        if (kDebugMode) {
          print('AudioService: Error playing recording: $e');
          print(
              'AudioService: Recording was public: ${recording.publicLink != null}');
          print(
              'AudioService: Had driveFileId: ${recording.driveFileId != null}');
          print('AudioService: Used URL: $audioUrl');
        }

        String errorMessage = 'Failed to play recording';
        if (e.toString().contains('404') ||
            e.toString().contains('Source error')) {
          errorMessage = 'Recording file not found or link expired';

          // Try to regenerate the URL if we have a driveFileId
          if (recording.driveFileId != null && recording.isPublic) {
            if (kDebugMode) {
              print('AudioService: Attempting to regenerate public URL...');
            }
            try {
              final driveService = GoogleDriveService();
              final newUrl =
                  await driveService.getPublicLink(recording.driveFileId!);
              if (newUrl != null) {
                if (kDebugMode) {
                  print('AudioService: Generated new URL: $newUrl');
                  print('AudioService: Retrying playback with new URL...');
                }
                // Retry with the new URL
                await playHymn(hymn, customAudioUrl: newUrl);
                return; // Success, exit function
              }
            } catch (retryError) {
              if (kDebugMode) {
                print('AudioService: URL regeneration failed: $retryError');
              }
            }

            // If URL regeneration failed, try refreshing all public URLs
            if (kDebugMode) {
              print('AudioService: Attempting to refresh all public URLs...');
            }
            try {
              final recordingService = RecordingService.to;
              await recordingService.refreshPublicUrls();

              // Try to get the updated recording and retry
              final recordings = recordingService.recordings;
              final updatedRecording =
                  recordings.firstWhereOrNull((r) => r.id == recording.id);
              if (updatedRecording != null &&
                  updatedRecording.publicLink != null) {
                if (kDebugMode) {
                  print(
                      'AudioService: Found updated recording, retrying with new URL: ${updatedRecording.publicLink}');
                }
                await playHymn(hymn,
                    customAudioUrl: updatedRecording.publicLink!);
                return; // Success, exit function
              }
            } catch (refreshError) {
              if (kDebugMode) {
                print('AudioService: Public URL refresh failed: $refreshError');
              }
            }
          }
        } else if (e.toString().contains('network') ||
            e.toString().contains('connection')) {
          errorMessage = 'Network connection error';
        } else {
          errorMessage = 'Playback error: ${e.toString()}';
        }

        UIService.showAudioPlaybackErrorSnackBar(errorMessage);
      }
    } else {
      if (kDebugMode) {
        print('AudioService: No audio URL found for recording ${recording.id}');
        print('AudioService: publicLink: ${recording.publicLink}');
        print('AudioService: driveFileId: ${recording.driveFileId}');
        print('AudioService: filePath: ${recording.filePath}');
      }

      UIService.showAudioNotAvailableSnackBar();
    }
  }

  /// Get the duration of an audio file without playing it
  /// Returns duration in seconds, or 0 if unable to determine
  static Future<int> getAudioFileDuration(String filePath) async {
    try {
      if (kDebugMode) {
        print('AudioService: Getting duration for file: $filePath');
      }

      // Check if file exists
      final file = File(filePath);
      if (!await file.exists()) {
        if (kDebugMode) {
          print('AudioService: File does not exist: $filePath');
        }
        return 0;
      }

      // Create a temporary player to get duration
      final tempPlayer = AudioPlayer();
      try {
        // Set the audio source and wait for it to load
        await tempPlayer.setFilePath(filePath);

        // Get the duration
        final duration = tempPlayer.duration;
        if (duration != null) {
          final durationInSeconds = duration.inSeconds;
          if (kDebugMode) {
            print(
                'AudioService: Duration for $filePath: ${durationInSeconds}s');
          }
          return durationInSeconds;
        } else {
          if (kDebugMode) {
            print('AudioService: Could not determine duration for $filePath');
          }
          return 0;
        }
      } finally {
        // Always dispose the temporary player
        await tempPlayer.dispose();
      }
    } catch (e) {
      if (kDebugMode) {
        print('AudioService: Error getting duration for $filePath: $e');
      }
      return 0;
    }
  }

  /// Get the duration of an audio file from URL without playing it
  /// Returns duration in seconds, or 0 if unable to determine
  static Future<int> getAudioUrlDuration(String url) async {
    try {
      if (kDebugMode) {
        print('AudioService: Getting duration for URL: $url');
      }

      // Create a temporary player to get duration
      final tempPlayer = AudioPlayer();
      try {
        // Set the audio source and wait for it to load
        await tempPlayer.setUrl(url);

        // Get the duration
        final duration = tempPlayer.duration;
        if (duration != null) {
          final durationInSeconds = duration.inSeconds;
          if (kDebugMode) {
            print('AudioService: Duration for $url: ${durationInSeconds}s');
          }
          return durationInSeconds;
        } else {
          if (kDebugMode) {
            print('AudioService: Could not determine duration for $url');
          }
          return 0;
        }
      } finally {
        // Always dispose the temporary player
        await tempPlayer.dispose();
      }
    } catch (e) {
      if (kDebugMode) {
        print('AudioService: Error getting duration for $url: $e');
      }
      return 0;
    }
  }
}
