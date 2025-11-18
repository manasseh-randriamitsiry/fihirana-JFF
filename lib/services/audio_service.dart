import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../models/hymn.dart';

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
    // Listen to player state changes to clear current playing hymn when playback stops
    _player.playerStateStream.listen((state) {
      print('AudioService: Player state changed - playing: ${state.playing}, processingState: ${state.processingState}');
      if (state.processingState == ProcessingState.completed ||
          (state.playing == false && _currentPlayingHymnId.value.isNotEmpty)) {
        print('AudioService: Clearing playing hymn ${_currentPlayingHymnId.value}');
        _currentPlayingHymnId.value = '';
      }
    });
  }

  final AudioPlayer _player = AudioPlayer();
  Hymn? _currentHymn;
  final Map<String, bool> _audioFileCache = {};
  final RxString _currentPlayingHymnId = ''.obs;

  AudioPlayer get player => _player;
  Hymn? get currentHymn => _currentHymn;

  Future<bool> checkAudioFileExists(String hymnId) async {
    // Check cache first
    if (_audioFileCache.containsKey(hymnId)) {
      return _audioFileCache[hymnId]!;
    }

    final audioUrl = 'https://raw.githubusercontent.com/manasseh-randriamitsiry/Fihirana-audio/main/$hymnId.mp3';
    
    try {
      final response = await http.head(Uri.parse(audioUrl));
      final exists = response.statusCode == 200;
      _audioFileCache[hymnId] = exists;
      return exists;
    } catch (e) {
      _audioFileCache[hymnId] = false;
      return false;
    }
  }

  Future<void> playHymn(Hymn hymn) async {
    _currentHymn = hymn;
    _currentPlayingHymnId.value = hymn.id;
    print('AudioService: Setting playing hymn to ${hymn.id}');
    
    final audioUrl = 'https://raw.githubusercontent.com/manasseh-randriamitsiry/Fihirana-audio/main/${hymn.id}.mp3';
    
    try {
      await _player.setUrl(audioUrl);
      await _player.play();
      print('AudioService: Started playing hymn ${hymn.id}');
    } catch (e) {
      _currentPlayingHymnId.value = '';
      print('AudioService: Error playing hymn ${hymn.id}: $e');
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
    await _player.stop();
    _currentHymn = null;
    _currentPlayingHymnId.value = '';
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
  }

  // Getters for reactive state
  String get currentPlayingHymnId => _currentPlayingHymnId.value;
  RxString get currentPlayingHymnIdRx => _currentPlayingHymnId;

  bool isHymnPlaying(String hymnId) {
    final result = _currentPlayingHymnId.value == hymnId && isPlaying;
    print('AudioService: isHymnPlaying($hymnId) = $result (current: ${_currentPlayingHymnId.value}, isPlaying: $isPlaying)');
    return result;
  }
}