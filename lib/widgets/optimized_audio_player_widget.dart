import 'dart:async';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:just_audio/just_audio.dart';
import '../models/hymn.dart';
import '../services/audio_service.dart';
import '../controller/color_controller.dart';
import 'package:get/get.dart';

class OptimizedAudioPlayerWidget extends StatefulWidget {
  final Hymn hymn;
  final bool isCompact;
  final List<Hymn>? playlist;
  final Function(Hymn)? onHymnChange;
  final bool autoPlayNext;
  final Function(bool)? onAutoPlayNextChange;

  const OptimizedAudioPlayerWidget({
    Key? key,
    required this.hymn,
    this.isCompact = false,
    this.playlist,
    this.onHymnChange,
    this.autoPlayNext = false,
    this.onAutoPlayNextChange,
  }) : super(key: key);

  @override
  State<OptimizedAudioPlayerWidget> createState() => _OptimizedAudioPlayerWidgetState();
}

class _OptimizedAudioPlayerWidgetState extends State<OptimizedAudioPlayerWidget>
    with TickerProviderStateMixin {
  final AudioService _audioService = AudioService.instance;
  final ColorController _colorController = Get.find<ColorController>();
  
  bool _isLoading = false;
  Duration? _duration;
  Duration? _position;
  bool _isPlaying = false;
  bool _showLyricsSection = false;
  int _currentPlaylistIndex = 0;
  bool _autoPlayNext = false;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;

  @override
  void initState() {
    super.initState();
    _autoPlayNext = widget.autoPlayNext;
    _initializeAnimations();
    _initializePlayer();
    
    if (widget.playlist != null) {
      _currentPlaylistIndex = widget.playlist!.indexWhere(
        (hymn) => hymn.id == widget.hymn.id,
      );
    }
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _initializePlayer() {
    _updateCurrentState();
    
    // Combine stream subscriptions to reduce rebuilds
    _playerStateSubscription = _audioService.playerStateStream.listen((state) {
      if (!mounted) return;
      
      if (_audioService.currentHymn?.id == widget.hymn.id) {
        final wasPlaying = _isPlaying;
        final isLoading = state.processingState == ProcessingState.loading ||
                        state.processingState == ProcessingState.buffering;
        
        if (wasPlaying != state.playing || _isLoading != isLoading) {
          setState(() {
            _isPlaying = state.playing;
            _isLoading = isLoading;
          });
          
          if (_isPlaying && mounted) {
            _pulseController.repeat(reverse: true);
          } else {
            _pulseController.stop();
            _pulseController.reset();
          }
        }
        
        // Handle auto-play next when current track completes
        if (state.processingState == ProcessingState.completed && _autoPlayNext && widget.playlist != null) {
          _updateCurrentPlaylistIndex();
          _playNext();
        }
      }
    });

    _positionSubscription = _audioService.positionStream.listen((position) {
      if (mounted && _audioService.currentHymn?.id == widget.hymn.id) {
        if (_position != position) {
          setState(() {
            _position = position;
          });
        }
      }
    });

    _durationSubscription = _audioService.durationStream.listen((duration) {
      if (mounted && _audioService.currentHymn?.id == widget.hymn.id) {
        if (_duration != duration) {
          setState(() {
            _duration = duration;
          });
        }
      }
    });
  }

  void _updateCurrentState() {
    if (!mounted) return;
    
    final currentHymn = _audioService.currentHymn;
    if (currentHymn?.id == widget.hymn.id) {
      setState(() {
        _isPlaying = _audioService.isPlaying;
        _isLoading = false;
      });
      
      if (_isPlaying && mounted) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    } else {
      setState(() {
        _isPlaying = false;
        _isLoading = false;
      });
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  void _updateCurrentPlaylistIndex() {
    if (widget.playlist == null) return;
    
    final currentIndex = widget.playlist!.indexWhere(
      (hymn) => hymn.id == widget.hymn.id,
    );
    if (currentIndex != -1) {
      _currentPlaylistIndex = currentIndex;
    }
  }

  Future<void> _playNext() async {
    if (widget.playlist == null || widget.playlist!.isEmpty) return;
    
    final nextIndex = (_currentPlaylistIndex + 1) % widget.playlist!.length;
    final nextHymn = widget.playlist![nextIndex];
    
    if (widget.onHymnChange != null) {
      widget.onHymnChange!(nextHymn);
    }
    
    await _audioService.playHymn(nextHymn);
  }

  Future<void> _playPrevious() async {
    if (widget.playlist == null || widget.playlist!.isEmpty) return;
    
    final prevIndex = _currentPlaylistIndex == 0 
        ? widget.playlist!.length - 1 
        : _currentPlaylistIndex - 1;
    final prevHymn = widget.playlist![prevIndex];
    
    if (widget.onHymnChange != null) {
      widget.onHymnChange!(prevHymn);
    }
    
    await _audioService.playHymn(prevHymn);
  }

  Future<void> _togglePlayPause() async {
    if (_isLoading) return;
    
    if (_audioService.currentHymn?.id == widget.hymn.id) {
      if (_isPlaying) {
        await _audioService.pause();
      } else {
        await _audioService.resume();
      }
    } else {
      await _audioService.playHymn(widget.hymn);
    }
  }

  Future<void> _seekToPosition(double position) async {
    if (_duration != null) {
      await _audioService.seekTo(Duration(
        milliseconds: (position * _duration!.inMilliseconds).round(),
      ));
    }
  }

  void _toggleLyricsSection() {
    setState(() {
      _showLyricsSection = !_showLyricsSection;
    });
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return _buildCompactPlayer();
    }
    
    return GetBuilder<ColorController>(
      builder: (colorController) => NeumorphicTheme(
        themeMode: colorController.themeMode,
        theme: colorController.getNeumorphicLightTheme(),
        darkTheme: colorController.getNeumorphicDarkTheme(),
        child: Neumorphic(
          style: NeumorphicStyle(
            depth: 8,
            intensity: 0.8,
            color: colorController.backgroundColor.value,
            boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(20)),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildProgressBar(),
                const SizedBox(height: 12),
                _buildMainControls(),
                if (widget.hymn.verses.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildLyricsToggle(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactPlayer() {
    return GetBuilder<ColorController>(
      builder: (colorController) => NeumorphicTheme(
        themeMode: colorController.themeMode,
        theme: colorController.getNeumorphicLightTheme(),
        darkTheme: colorController.getNeumorphicDarkTheme(),
        child: Neumorphic(
          style: NeumorphicStyle(
            depth: 4,
            intensity: 0.8,
            color: colorController.backgroundColor.value,
            boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                NeumorphicButton(
                  style: NeumorphicStyle(
                    depth: 2,
                    color: colorController.backgroundColor.value,
                    boxShape: NeumorphicBoxShape.circle(),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorController.primaryColor.value,
                          ),
                        )
                      : AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _isPlaying ? _pulseAnimation.value : 1.0,
                              child: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                size: 24,
                                color: colorController.primaryColor.value,
                              ),
                            );
                          },
                        ),
                  onPressed: _isLoading ? null : _togglePlayPause,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                      trackHeight: 2,
                      activeTrackColor: colorController.primaryColor.value,
                      inactiveTrackColor: colorController.textColor.value.withOpacity(0.3),
                      thumbColor: colorController.primaryColor.value,
                    ),
                    child: Slider(
                      value: _position?.inMilliseconds.toDouble() ?? 0.0,
                      max: _duration?.inMilliseconds.toDouble() ?? 0.0,
                      onChanged: _isLoading ? null : _seekToPosition,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.hymn.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _colorController.textColor.value,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Hymn ${widget.hymn.hymnNumber}',
                style: TextStyle(
                  fontSize: 14,
                  color: _colorController.textColor.value.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        if (widget.playlist != null && widget.playlist!.length > 1) ...[
          const SizedBox(width: 12),
          NeumorphicButton(
            style: NeumorphicStyle(
              depth: 2,
              color: _colorController.backgroundColor.value,
              boxShape: NeumorphicBoxShape.circle(),
            ),
            child: Icon(
              Icons.skip_previous,
              size: 24,
              color: _colorController.primaryColor.value,
            ),
            onPressed: _isLoading ? null : _playPrevious,
          ),
          const SizedBox(width: 8),
          NeumorphicButton(
            style: NeumorphicStyle(
              depth: 2,
              color: _colorController.backgroundColor.value,
              boxShape: NeumorphicBoxShape.circle(),
            ),
            child: Icon(
              Icons.skip_next,
              size: 24,
              color: _colorController.primaryColor.value,
            ),
            onPressed: _isLoading ? null : _playNext,
          ),
        ],
      ],
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            trackHeight: 4,
            activeTrackColor: _colorController.primaryColor.value,
            inactiveTrackColor: _colorController.textColor.value.withOpacity(0.3),
            thumbColor: _colorController.primaryColor.value,
          ),
          child: Slider(
            value: _position?.inMilliseconds.toDouble() ?? 0.0,
            max: _duration?.inMilliseconds.toDouble() ?? 0.0,
            onChanged: _isLoading ? null : _seekToPosition,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(_position ?? Duration.zero),
              style: TextStyle(
                fontSize: 12,
                color: _colorController.textColor.value.withOpacity(0.7),
              ),
            ),
            Text(
              _formatDuration(_duration ?? Duration.zero),
              style: TextStyle(
                fontSize: 12,
                color: _colorController.textColor.value.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        NeumorphicButton(
          style: NeumorphicStyle(
            depth: 3,
            color: _colorController.backgroundColor.value,
            boxShape: NeumorphicBoxShape.circle(),
          ),
          child: Container(
            width: 56,
            height: 56,
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: _colorController.primaryColor.value,
                    ),
                  )
                : AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isPlaying ? _pulseAnimation.value : 1.0,
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 32,
                          color: _colorController.primaryColor.value,
                        ),
                      );
                    },
                  ),
          ),
          onPressed: _isLoading ? null : _togglePlayPause,
        ),
      ],
    );
  }

  Widget _buildLyricsToggle() {
    return NeumorphicButton(
      style: NeumorphicStyle(
        depth: 2,
        color: _colorController.backgroundColor.value,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _showLyricsSection ? Icons.expand_less : Icons.expand_more,
              size: 20,
              color: _colorController.primaryColor.value,
            ),
            const SizedBox(width: 8),
            Text(
              'Lyrics',
              style: TextStyle(
                fontSize: 14,
                color: _colorController.primaryColor.value,
              ),
            ),
          ],
        ),
      ),
      onPressed: _toggleLyricsSection,
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}