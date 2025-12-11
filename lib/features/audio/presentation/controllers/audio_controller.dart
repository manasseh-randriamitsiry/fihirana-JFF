import 'dart:async';
import 'package:get/get.dart';
import 'package:fihirana/features/audio/domain/entities/audio_player_state.dart';
import 'package:fihirana/features/audio/domain/repositories/audio_repository.dart';
import 'package:fihirana/features/audio/domain/usecases/play_hymn_usecase.dart';
import 'package:fihirana/features/audio/domain/usecases/pause_audio_usecase.dart';
import 'package:fihirana/features/audio/domain/usecases/resume_audio_usecase.dart';
import 'package:fihirana/features/audio/domain/usecases/stop_audio_usecase.dart';
import 'package:fihirana/features/audio/domain/usecases/set_playlist_usecase.dart';
import 'package:fihirana/features/audio/domain/usecases/play_next_usecase.dart';
import 'package:fihirana/features/audio/domain/usecases/play_previous_usecase.dart';
import 'package:fihirana/features/audio/domain/usecases/check_audio_exists_usecase.dart';
import 'package:fihirana/features/audio/domain/usecases/download_audio_usecase.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/core/error/error_handler.dart';

class AudioController extends GetxController {
  final PlayHymnUseCase _playHymnUseCase;
  final PauseAudioUseCase _pauseAudioUseCase;
  final ResumeAudioUseCase _resumeAudioUseCase;
  final StopAudioUseCase _stopAudioUseCase;
  final SetPlaylistUseCase _setPlaylistUseCase;
  final PlayNextUseCase _playNextUseCase;
  final PlayPreviousUseCase _playPreviousUseCase;
  final CheckAudioExistsUseCase _checkAudioExistsUseCase;
  final DownloadAudioUseCase _downloadAudioUseCase;
  final AudioRepository _repository;

  AudioController({
    required PlayHymnUseCase playHymnUseCase,
    required PauseAudioUseCase pauseAudioUseCase,
    required ResumeAudioUseCase resumeAudioUseCase,
    required StopAudioUseCase stopAudioUseCase,
    required SetPlaylistUseCase setPlaylistUseCase,
    required PlayNextUseCase playNextUseCase,
    required PlayPreviousUseCase playPreviousUseCase,
    required CheckAudioExistsUseCase checkAudioExistsUseCase,
    required DownloadAudioUseCase downloadAudioUseCase,
    required AudioRepository repository,
  })  : _playHymnUseCase = playHymnUseCase,
        _pauseAudioUseCase = pauseAudioUseCase,
        _resumeAudioUseCase = resumeAudioUseCase,
        _stopAudioUseCase = stopAudioUseCase,
        _setPlaylistUseCase = setPlaylistUseCase,
        _playNextUseCase = playNextUseCase,
        _playPreviousUseCase = playPreviousUseCase,
        _checkAudioExistsUseCase = checkAudioExistsUseCase,
        _downloadAudioUseCase = downloadAudioUseCase,
        _repository = repository;

  // Reactive state
  final Rx<AudioPlayerState> _playerState = const AudioPlayerState().obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;

  // Stream subscriptions
  late StreamSubscription<AudioPlayerState> _playerStateSubscription;
  late StreamSubscription<Duration> _positionSubscription;
  late StreamSubscription<Duration> _durationSubscription;

  // Getters
  AudioPlayerState get playerState => _playerState.value;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  Hymn? get currentHymn => _playerState.value.currentHymn;
  bool get isPlaying => _playerState.value.isPlaying;
  bool get hasError => _playerState.value.hasError;
  Duration get currentPosition => _playerState.value.position;
  Duration get duration => _playerState.value.duration;
  bool get canPlayNext => _playerState.value.canPlayNext;
  bool get canPlayPrevious => _playerState.value.canPlayPrevious;
  List<Hymn> get playlist => _playerState.value.playlist;
  int get currentPlaylistIndex => _playerState.value.currentPlaylistIndex;

  @override
  void onInit() {
    super.onInit();
    _initializeState();
    _subscribeToStreams();
  }

  void _initializeState() {
    _playerState.value = _repository.currentState;
  }

  void _subscribeToStreams() {
    _playerStateSubscription = _repository.playerStateStream.listen(
      (state) {
        _playerState.value = state;
        _clearError();
      },
      onError: (error) {
        ErrorHandler.handleError(error, message: 'errorOccurred'.tr);
      },
    );

    _positionSubscription = _repository.positionStream.listen(
      (position) {
        _playerState.value = _playerState.value.copyWith(position: position);
      },
    );

    _durationSubscription = _repository.durationStream.listen(
      (duration) {
        _playerState.value = _playerState.value.copyWith(duration: duration);
      },
    );
  }

  // Player control methods
  Future<void> playHymn(Hymn hymn, {String? customAudioUrl}) async {
    try {
      _setLoading(true);
      _clearError();
      await _playHymnUseCase(hymn, customAudioUrl: customAudioUrl);
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorPlayingAudio'.tr);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> pause() async {
    try {
      _clearError();
      await _pauseAudioUseCase();
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorOccurred'.tr);
    }
  }

  Future<void> resume() async {
    try {
      _clearError();
      await _resumeAudioUseCase();
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorOccurred'.tr);
    }
  }

  Future<void> stop() async {
    try {
      _clearError();
      await _stopAudioUseCase();
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorOccurred'.tr);
    }
  }

  Future<void> playNext() async {
    try {
      _clearError();
      await _playNextUseCase();
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorPlayingNextHymn'.tr);
    }
  }

  Future<void> playPrevious() async {
    try {
      _clearError();
      await _playPreviousUseCase();
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorPlayingPreviousHymn'.tr);
    }
  }

  Future<void> seekTo(Duration position) async {
    try {
      _clearError();
      await _repository.seekTo(position);
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorOccurred'.tr);
    }
  }

  // Playlist management
  Future<void> setPlaylist(List<Hymn> playlist, int initialIndex) async {
    try {
      _clearError();
      await _setPlaylistUseCase(playlist, initialIndex);
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorOccurred'.tr);
    }
  }

  // Audio availability and downloading
  Future<bool> checkAudioExists(String hymnId) async {
    try {
      return await _checkAudioExistsUseCase(hymnId);
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorOccurred'.tr);
      return false;
    }
  }

  Future<void> downloadAudio(Hymn hymn, {Function(double)? onProgress}) async {
    try {
      _setLoading(true);
      _clearError();
      await _downloadAudioUseCase(hymn, onProgress: onProgress);
    } catch (e) {
      ErrorHandler.handleError(e, message: 'cannotDownload'.tr);
    } finally {
      _setLoading(false);
    }
  }

  // Recording playback
  Future<void> playRecording(dynamic recording) async {
    try {
      _setLoading(true);
      _clearError();
      await _repository.playRecording(recording);
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorOccurred'.tr);
    } finally {
      _setLoading(false);
    }
  }

  // Utility methods
  String get currentDisplayTitle {
    if (_repository.currentHymn?.id.startsWith('recording_') == true) {
      return _repository.currentHymn?.title ?? '';
    }
    return _repository.currentHymn?.title ?? '';
  }

  String get currentDisplaySubtitle {
    if (_repository.currentHymn?.id.startsWith('recording_') == true) {
      return 'Recording';
    }
    return _repository.currentHymn != null 
        ? 'Hymn ${_repository.currentHymn!.hymnNumber}' 
        : '';
  }

  // State management helpers
  void _setLoading(bool loading) {
    _isLoading.value = loading;
    _playerState.value = _playerState.value.copyWith(isLoading: loading);
  }



  void _clearError() {
    if (_error.value.isNotEmpty) {
      _error.value = '';
      _playerState.value = _playerState.value.copyWith(error: null);
    }
  }

  @override
  void onClose() {
    _playerStateSubscription.cancel();
    _positionSubscription.cancel();
    _durationSubscription.cancel();
    super.onClose();
  }
}