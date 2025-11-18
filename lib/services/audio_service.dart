import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import '../models/hymn.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  Hymn? _currentHymn;
  final Map<String, bool> _audioFileCache = {};

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
    
    final audioUrl = 'https://raw.githubusercontent.com/manasseh-randriamitsiry/Fihirana-audio/main/${hymn.id}.mp3';
    
    try {
      await _player.setUrl(audioUrl);
      await _player.play();
    } catch (e) {
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
  }
}