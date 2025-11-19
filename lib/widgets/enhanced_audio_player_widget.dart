import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/hymn.dart';
import '../services/audio_service.dart';
import '../controller/color_controller.dart';
import 'package:get/get.dart';

class EnhancedAudioPlayerWidget extends StatefulWidget {
  final Hymn hymn;
  final bool isCompact;
  final List<Hymn>? playlist;
  final Function(Hymn)? onHymnChange;
  final bool autoPlayNext;
  final Function(bool)? onAutoPlayNextChange;

  const EnhancedAudioPlayerWidget({
    super.key,
    required this.hymn,
    this.isCompact = false,
    this.playlist,
    this.onHymnChange,
    this.autoPlayNext = false,
    this.onAutoPlayNextChange,
  });

  @override
  State<EnhancedAudioPlayerWidget> createState() => _EnhancedAudioPlayerWidgetState();
}

class _EnhancedAudioPlayerWidgetState extends State<EnhancedAudioPlayerWidget>
    with TickerProviderStateMixin {
  final AudioService _audioService = AudioService.instance;
  final ColorController _colorController = Get.find<ColorController>();
  
  bool _isLoading = false;
  Duration? _duration;
  Duration? _position;
  bool _isPlaying = false;
  int _currentPlaylistIndex = 0;
  bool _autoPlayNext = false;
  ScrollController _lyricsScrollController = ScrollController();
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

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

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _slideController.forward();
  }

  void _initializePlayer() {
    _updateCurrentState();
    
    _playerStateSubscription = _audioService.playerStateStream.listen((state) {
      if (mounted) {
        if (_audioService.currentHymn?.id == widget.hymn.id) {
          setState(() {
            _isPlaying = state.playing;
            _isLoading = state.processingState == ProcessingState.loading ||
                        state.processingState == ProcessingState.buffering;
          });
          
          if (_isPlaying && mounted) {
            _pulseController.repeat(reverse: true);
          } else {
            _pulseController.stop();
            _pulseController.reset();
          }
          
          // Handle auto-play next when current track completes
          if (state.processingState == ProcessingState.completed && _autoPlayNext && widget.playlist != null) {
            // Update current index before playing next
            _updateCurrentPlaylistIndex();
            _playNext();
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
    });

    _positionSubscription = _audioService.positionStream.listen((position) {
      if (mounted && _audioService.currentHymn?.id == widget.hymn.id) {
        // Validate position before setting state
        if (position != null && position >= Duration.zero) {
          setState(() {
            _position = position;
          });
        }
      }
    });

    _durationSubscription = _audioService.durationStream.listen((duration) {
      if (mounted && _audioService.currentHymn?.id == widget.hymn.id) {
        // Validate duration before setting state
        if (duration != null && duration >= Duration.zero) {
          setState(() {
            _duration = duration;
          });
        }
      }
    });
  }

  void _updateCurrentState() {
    if (!mounted) return;
    
    if (_audioService.currentHymn?.id == widget.hymn.id) {
      setState(() {
        _isPlaying = _audioService.isPlaying;
        _position = _audioService.currentPosition;
        _duration = _audioService.duration;
      });
    } else {
      setState(() {
        _isPlaying = false;
        _isLoading = false;
        _position = null;
        _duration = null;
      });
    }
  }

  void _updateCurrentPlaylistIndex() {
    if (widget.playlist != null && _audioService.currentHymn != null) {
      final currentIndex = widget.playlist!.indexWhere(
        (hymn) => hymn.id == _audioService.currentHymn!.id,
      );
      if (currentIndex != -1) {
        _currentPlaylistIndex = currentIndex;
      }
    }
  }

  void _toggleAutoPlay() {
    setState(() {
      _autoPlayNext = !_autoPlayNext;
    });
    widget.onAutoPlayNextChange?.call(_autoPlayNext);
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_audioService.currentHymn?.id != widget.hymn.id) {
        setState(() => _isLoading = true);
        
        if (_audioService.currentPlayingHymnId.isNotEmpty) {
          await _audioService.stopCurrentAndPlayNew(widget.hymn);
        } else {
          await _audioService.playHymn(widget.hymn);
        }
      } else if (_isPlaying) {
        await _audioService.pause();
      } else {
        await _audioService.resume();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to play audio: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _stop() async {
    try {
      await _audioService.stop();
    } catch (e) {
      _showErrorSnackBar('Failed to stop audio: $e');
    }
  }

  double _calculateSliderValue() {
    if (_duration == null || _position == null) return 0.0;
    
    final durationMs = _duration!.inMilliseconds.toDouble();
    final positionMs = _position!.inMilliseconds.toDouble();
    
    if (durationMs <= 0) return 0.0;
    
    // Additional safety check for extreme values
    if (positionMs < 0) return 0.0;
    
    final value = positionMs / durationMs;
    final clampedValue = value.clamp(0.0, 1.0);
    
    // Debug logging for troubleshooting
    if (clampedValue != value) {
      print('EnhancedAudioPlayerWidget: Clamped slider value from $value to $clampedValue (pos: $positionMs, dur: $durationMs)');
    }
    
    return clampedValue;
  }

  Future<void> _seekTo(double value) async {
    if (_duration == null) return;
    
    final clampedValue = value.clamp(0.0, 1.0);
    final position = Duration(
      milliseconds: (clampedValue * _duration!.inMilliseconds).round(),
    );
    await _audioService.seekTo(position);
  }

  Future<void> _playNext() async {
    if (widget.playlist != null) {
      // First update current index to ensure we're at the right position
      _updateCurrentPlaylistIndex();
      
      if (_currentPlaylistIndex < widget.playlist!.length - 1) {
        final nextHymn = widget.playlist![_currentPlaylistIndex + 1];
        setState(() {
          _currentPlaylistIndex++;
        });
        widget.onHymnChange?.call(nextHymn);
        await _audioService.stopCurrentAndPlayNew(nextHymn);
      }
    }
  }

  Future<void> _playPrevious() async {
    if (widget.playlist != null) {
      // First update current index to ensure we're at the right position
      _updateCurrentPlaylistIndex();
      
      if (_currentPlaylistIndex > 0) {
        final previousHymn = widget.playlist![_currentPlaylistIndex - 1];
        setState(() {
          _currentPlaylistIndex--;
        });
        widget.onHymnChange?.call(previousHymn);
        await _audioService.stopCurrentAndPlayNew(previousHymn);
      }
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return _buildCompactPlayer();
    }
    
    return GetBuilder<ColorController>(
      builder: (colorController) => SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: colorController.backgroundColor.value,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
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
                  _buildLyricsSection(),
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
      builder: (colorController) => Container(
        decoration: BoxDecoration(
          color: colorController.backgroundColor.value,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: colorController.backgroundColor.value,
                    ),
                    onPressed: _isLoading ? null : _togglePlayPause,
                    icon: _isLoading
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
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                        trackHeight: 2,
                        activeTrackColor: colorController.primaryColor.value,
                        inactiveTrackColor: colorController.primaryColor.value.withOpacity(0.3),
                        thumbColor: colorController.primaryColor.value,
                      ),
                      child: Slider(
                        value: _calculateSliderValue().clamp(0.0, 1.0),
                        onChanged: _duration != null ? _seekTo : null,
                        min: 0.0,
                        max: 1.0,
                      ),
                    ),
                  ),
                  Text(
                    _formatDuration(_duration),
                    style: TextStyle(
                      fontSize: 10,
                      color: colorController.textColor.value.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          widget.hymn.title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _colorController.textColor.value,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Hymn ${widget.hymn.hymnNumber}',
              style: TextStyle(
                fontSize: 14,
                color: _colorController.textColor.value.withOpacity(0.7),
              ),
            ),
            if (widget.playlist != null) ...[
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _toggleAutoPlay,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _autoPlayNext
                        ? _colorController.primaryColor.value.withOpacity(0.2)
                        : _colorController.backgroundColor.value,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _colorController.primaryColor.value.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _autoPlayNext ? Icons.play_circle : Icons.playlist_play,
                        size: 14,
                        color: _autoPlayNext
                            ? _colorController.primaryColor.value
                            : _colorController.textColor.value.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _autoPlayNext ? 'Auto' : 'Single',
                        style: TextStyle(
                          fontSize: 12,
                          color: _autoPlayNext
                              ? _colorController.primaryColor.value
                              : _colorController.textColor.value.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Row(
          children: [
            Text(
              _formatDuration(_position),
              style: TextStyle(
                fontSize: 12,
                color: _colorController.textColor.value.withOpacity(0.7),
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  trackHeight: 4,
                  activeTrackColor: _colorController.primaryColor.value,
                  inactiveTrackColor: _colorController.primaryColor.value.withOpacity(0.3),
                  thumbColor: _colorController.primaryColor.value,
                ),
                child: Slider(
                  value: _calculateSliderValue().clamp(0.0, 1.0),
                  onChanged: _duration != null ? _seekTo : null,
                  min: 0.0,
                  max: 1.0,
                ),
              ),
            ),
            Text(
              _formatDuration(_duration),
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
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (widget.playlist != null) ...[
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: _colorController.backgroundColor.value,
            ),
            onPressed: _currentPlaylistIndex > 0 ? _playPrevious : null,
            icon: Icon(
              Icons.skip_previous,
              color: _colorController.iconColor.value,
              size: 24,
            ),
          ),
        ],
        
        IconButton(
          style: IconButton.styleFrom(
            backgroundColor: _colorController.primaryColor.value,
          ),
          onPressed: _isLoading ? null : _togglePlayPause,
          icon: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isPlaying ? _pulseAnimation.value : 1.0,
                child: _isLoading
                    ? SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _colorController.backgroundColor.value,
                          ),
                        ),
                      )
                    : Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 32,
                        color: _colorController.backgroundColor.value,
                      ),
              );
            },
          ),
        ),
        
        if (widget.playlist != null) ...[
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: _colorController.backgroundColor.value,
            ),
            onPressed: _currentPlaylistIndex < widget.playlist!.length - 1 ? _playNext : null,
            icon: Icon(
              Icons.skip_next,
              color: _colorController.iconColor.value,
              size: 24,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLyricsSection() {
    return Container(
      decoration: BoxDecoration(
        color: _colorController.backgroundColor.value,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _colorController.primaryColor.value.withOpacity(0.2),
        ),
      ),
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lyrics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _colorController.textColor.value,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                controller: _lyricsScrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.hymn.verses.isNotEmpty) ...[
                      ...widget.hymn.verses.asMap().entries.map((entry) {
                        final verseNumber = entry.key + 1;
                        final verseText = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Verse $verseNumber',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _colorController.primaryColor.value,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                verseText,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _colorController.textColor.value,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                    if (widget.hymn.bridge != null && widget.hymn.bridge!.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bridge',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _colorController.primaryColor.value,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.hymn.bridge!,
                              style: TextStyle(
                                fontSize: 14,
                                color: _colorController.textColor.value,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _pulseController.dispose();
    _slideController.dispose();
    _lyricsScrollController.dispose();
    
    // Cancel any pending futures or timers
    _isLoading = false;
    
    super.dispose();
  }
}