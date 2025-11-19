import 'dart:async';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:just_audio/just_audio.dart';
import '../models/hymn.dart';
import '../services/audio_service.dart';
import '../controller/color_controller.dart';
import 'package:get/get.dart';

class LightweightAudioPlayerWidget extends StatefulWidget {
  final Hymn hymn;
  final bool isCompact;
  final List<Hymn>? playlist;
  final Function(Hymn)? onHymnChange;
  final bool autoPlayNext;
  final Function(bool)? onAutoPlayNextChange;

  const LightweightAudioPlayerWidget({
    Key? key,
    required this.hymn,
    this.isCompact = false,
    this.playlist,
    this.onHymnChange,
    this.autoPlayNext = false,
    this.onAutoPlayNextChange,
  }) : super(key: key);

  @override
  State<LightweightAudioPlayerWidget> createState() => _LightweightAudioPlayerWidgetState();
}

class _LightweightAudioPlayerWidgetState extends State<LightweightAudioPlayerWidget> {
  final AudioService _audioService = AudioService.instance;
  final ColorController _colorController = Get.find<ColorController>();
  
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration? _duration;
  Duration? _position;
  int _currentPlaylistIndex = 0;
  bool _autoPlayNext = false;
  
  // Minimal subscriptions - only listen when absolutely necessary
  StreamSubscription? _playerStateSubscription;
  Timer? _positionUpdateTimer;

  @override
  void initState() {
    super.initState();
    _autoPlayNext = widget.autoPlayNext;
    
    // Only initialize what we absolutely need
    _initializeMinimalPlayer();
    
    if (widget.playlist != null) {
      _currentPlaylistIndex = widget.playlist!.indexWhere(
        (hymn) => hymn.id == widget.hymn.id,
      );
    }
  }

  void _initializeMinimalPlayer() {
    // Update current state once
    _updateCurrentState();
    
    // Only listen to player state changes - avoid position/duration streams for performance
    _playerStateSubscription = _audioService.playerStateStream.listen((state) {
      if (!mounted) return;
      
      if (_audioService.currentHymn?.id == widget.hymn.id) {
        final wasPlaying = _isPlaying;
        final isLoading = state.processingState == ProcessingState.loading ||
                        state.processingState == ProcessingState.buffering;
        
        // Only update state if something actually changed
        if (wasPlaying != state.playing || _isLoading != isLoading) {
          setState(() {
            _isPlaying = state.playing;
            _isLoading = isLoading;
          });
        }
        
        // Handle auto-play next when current track completes
        if (state.processingState == ProcessingState.completed && _autoPlayNext && widget.playlist != null) {
          _updateCurrentPlaylistIndex();
          _playNext();
        }
      }
    });
    
    // Use timer for position updates instead of stream (much lighter on CPU)
    _positionUpdateTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted || _audioService.currentHymn?.id != widget.hymn.id) {
        return;
      }
      
      _updatePositionAndDuration();
    });
  }

  void _updatePositionAndDuration() async {
    try {
      final position = _audioService.player.position;
      final duration = _audioService.player.duration;
      
      // Only update if values changed significantly
      if (_position == null || 
          (_position != null && (position - _position!).inMilliseconds.abs() > 500)) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      }
      
      if (_duration == null || 
          (_duration != null && (duration! - _duration!).inMilliseconds.abs() > 500)) {
        if (mounted) {
          setState(() {
            _duration = duration;
          });
        }
      }
    } catch (e) {
      // Ignore errors in position/duration updates
    }
  }

  void _updateCurrentState() {
    if (!mounted) return;
    
    final currentHymn = _audioService.currentHymn;
    if (currentHymn?.id == widget.hymn.id) {
      setState(() {
        _isPlaying = _audioService.isPlaying;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isPlaying = false;
        _isLoading = false;
      });
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

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _positionUpdateTimer?.cancel();
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
            depth: 6, // Reduced depth for performance
            intensity: 0.6, // Reduced intensity
            color: colorController.backgroundColor.value,
            boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
          ),
          child: Container(
            padding: const EdgeInsets.all(12), // Reduced padding
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                const SizedBox(height: 8), // Reduced spacing
                _buildProgressBar(),
                const SizedBox(height: 8), // Reduced spacing
                _buildMainControls(),
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
            depth: 3, // Reduced depth
            intensity: 0.6,
            color: colorController.backgroundColor.value,
            boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(10)),
          ),
          child: Container(
            padding: const EdgeInsets.all(8), // Reduced padding
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPlayButton(colorController),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMinimalSlider(colorController),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayButton(ColorController colorController) {
    return NeumorphicButton(
      style: NeumorphicStyle(
        depth: 1, // Minimal depth
        color: colorController.backgroundColor.value,
        boxShape: NeumorphicBoxShape.circle(),
      ),
      child: SizedBox(
        width: 32,
        height: 32,
        child: _isLoading
            ? Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5, // Thinner stroke
                    color: colorController.primaryColor.value,
                  ),
                ),
              )
            : Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                size: 18, // Smaller icon
                color: colorController.primaryColor.value,
              ),
      ),
      onPressed: _isLoading ? null : _togglePlayPause,
    );
  }

  Widget _buildMinimalSlider(ColorController colorController) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 3), // Smaller thumb
        trackHeight: 1.5, // Thinner track
        activeTrackColor: colorController.primaryColor.value,
        inactiveTrackColor: colorController.textColor.value.withOpacity(0.2),
        thumbColor: colorController.primaryColor.value,
      ),
      child: Slider(
        value: _position?.inMilliseconds.toDouble() ?? 0.0,
        max: _duration?.inMilliseconds.toDouble() ?? 0.0,
        onChanged: _isLoading ? null : _seekToPosition,
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
                  fontSize: 14, // Smaller font
                  fontWeight: FontWeight.w600, // Slightly lighter
                  color: _colorController.textColor.value,
                ),
                maxLines: 1, // Limit to 1 line for performance
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Hymn ${widget.hymn.hymnNumber}',
                style: TextStyle(
                  fontSize: 12,
                  color: _colorController.textColor.value.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        if (widget.playlist != null && widget.playlist!.length > 1) ...[
          const SizedBox(width: 8),
          _buildNavigationButton(Icons.skip_previous, _playPrevious),
          const SizedBox(width: 4),
          _buildNavigationButton(Icons.skip_next, _playNext),
        ],
      ],
    );
  }

  Widget _buildNavigationButton(IconData icon, VoidCallback onPressed) {
    return NeumorphicButton(
      style: NeumorphicStyle(
        depth: 1,
        color: _colorController.backgroundColor.value,
        boxShape: NeumorphicBoxShape.circle(),
      ),
      child: Icon(
        icon,
        size: 18, // Smaller icons
        color: _colorController.primaryColor.value,
      ),
      onPressed: _isLoading ? null : onPressed,
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
            trackHeight: 2,
            activeTrackColor: _colorController.primaryColor.value,
            inactiveTrackColor: _colorController.textColor.value.withOpacity(0.2),
            thumbColor: _colorController.primaryColor.value,
          ),
          child: Slider(
            value: _position?.inMilliseconds.toDouble() ?? 0.0,
            max: _duration?.inMilliseconds.toDouble() ?? 0.0,
            onChanged: _isLoading ? null : _seekToPosition,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(_position ?? Duration.zero),
              style: TextStyle(
                fontSize: 10, // Smaller font
                color: _colorController.textColor.value.withOpacity(0.6),
              ),
            ),
            Text(
              _formatDuration(_duration ?? Duration.zero),
              style: TextStyle(
                fontSize: 10,
                color: _colorController.textColor.value.withOpacity(0.6),
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
            depth: 2, // Reduced depth
            intensity: 0.6,
            color: _colorController.backgroundColor.value,
            boxShape: NeumorphicBoxShape.circle(),
          ),
          child: Container(
            width: 48, // Smaller button
            height: 48,
            child: _isLoading
                ? Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _colorController.primaryColor.value,
                      ),
                    ),
                  )
                : Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 24, // Smaller icon
                    color: _colorController.primaryColor.value,
                  ),
          ),
          onPressed: _isLoading ? null : _togglePlayPause,
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}