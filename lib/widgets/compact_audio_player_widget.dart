import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/hymn.dart';
import '../services/audio_service.dart';
import '../controller/color_controller.dart';
import 'package:get/get.dart';

class CompactAudioPlayerWidget extends StatefulWidget {
  final Hymn hymn;
  final List<Hymn>? playlist;
  final Function(Hymn)? onHymnChange;
  final bool autoPlayNext;
  final Function(bool)? onAutoPlayNextChange;

  const CompactAudioPlayerWidget({
    super.key,
    required this.hymn,
    this.playlist,
    this.onHymnChange,
    this.autoPlayNext = false,
    this.onAutoPlayNextChange,
  });

  @override
  State<CompactAudioPlayerWidget> createState() => _CompactAudioPlayerWidgetState();
}

class _CompactAudioPlayerWidgetState extends State<CompactAudioPlayerWidget> {
  final AudioService _audioService = AudioService.instance;
  bool _isLoading = false;
  Duration? _duration;
  Duration? _position;
  bool _isPlaying = false;
  bool _autoPlayNext = false;
  int _currentPlaylistIndex = 0;

  @override
  void initState() {
    super.initState();
    _autoPlayNext = widget.autoPlayNext;
    _initializePlayer();
    
    // Refresh audio service state to ensure consistency
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _audioService.refreshPlayingState();
    });
    
    if (widget.playlist != null) {
      _currentPlaylistIndex = widget.playlist!.indexWhere(
        (hymn) => hymn.id == widget.hymn.id,
      );
    }
  }

  @override
  void didUpdateWidget(CompactAudioPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If the hymn changed, update the state
    if (oldWidget.hymn.id != widget.hymn.id) {
      _updateCurrentState();
    }
  }

  void _initializePlayer() {
    // Initialize current state
    _updateCurrentState();
    
    // Listen to player state changes
    _audioService.playerStateStream.listen((state) {
      if (mounted) {
        print('CompactAudioPlayer: State changed for ${widget.hymn.id} - playing: ${state.playing}, processing: ${state.processingState}');
        
        // Only update state if this widget's hymn is the one currently playing
        if (_audioService.currentHymn?.id == widget.hymn.id) {
          setState(() {
            _isPlaying = state.playing;
            _isLoading = state.processingState == ProcessingState.loading ||
                        state.processingState == ProcessingState.buffering;
          });
          
          // Handle auto-play next when current track completes
          if (state.processingState == ProcessingState.completed && _autoPlayNext && widget.playlist != null) {
            _updateCurrentPlaylistIndex();
            _playNext();
          }
        } else {
          // If another hymn is playing, reset this widget's state
          setState(() {
            _isPlaying = false;
            _isLoading = false;
          });
        }
      }
    });

    _audioService.positionStream.listen((position) {
      if (mounted && _audioService.currentHymn?.id == widget.hymn.id) {
        // Validate position before setting state
        if (position != null && position >= Duration.zero) {
          setState(() {
            _position = position;
          });
        }
      }
    });

    _audioService.durationStream.listen((duration) {
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
      print('CompactAudioPlayer: Toggle play/pause for ${widget.hymn.id}');
      
      if (_audioService.currentHymn?.id != widget.hymn.id) {
        setState(() => _isLoading = true);
        
        // If another hymn is currently playing, stop it first
        if (_audioService.currentPlayingHymnId.isNotEmpty) {
          await _audioService.stopCurrentAndPlayNew(widget.hymn);
        } else {
          await _audioService.playHymn(widget.hymn);
        }
        
        // State will be updated by the stream listener
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
      print('CompactAudioPlayerWidget: Clamped slider value from $value to $clampedValue (pos: $positionMs, dur: $durationMs)');
    }
    
    return clampedValue;
  }

  void _seekTo(double value) {
    if (_duration == null) return;
    
    final clampedValue = value.clamp(0.0, 1.0);
    final position = Duration(milliseconds: (clampedValue * _duration!.inMilliseconds).round());
    _audioService.seekTo(position);
  }

  Future<void> _playNext() async {
    if (widget.playlist != null) {
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
    final ColorController colorController = Get.find<ColorController>();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorController.backgroundColor.value,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorController.primaryColor.value.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.hymn.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorController.textColor.value,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Hymn ${widget.hymn.hymnNumber}',
                style: TextStyle(
                  fontSize: 12,
                  color: colorController.textColor.value.withOpacity(0.7),
                ),
              ),
              if (widget.playlist != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _toggleAutoPlay,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _autoPlayNext
                          ? colorController.primaryColor.value.withOpacity(0.2)
                          : colorController.backgroundColor.value,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorController.primaryColor.value.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _autoPlayNext ? Icons.play_circle : Icons.playlist_play,
                          size: 12,
                          color: _autoPlayNext
                              ? colorController.primaryColor.value
                              : colorController.textColor.value.withOpacity(0.7),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _autoPlayNext ? 'Auto' : 'Single',
                          style: TextStyle(
                            fontSize: 10,
                            color: _autoPlayNext
                                ? colorController.primaryColor.value
                                : colorController.textColor.value.withOpacity(0.7),
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
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                _formatDuration(_position),
                style: TextStyle(
                  fontSize: 10,
                  color: colorController.textColor.value.withOpacity(0.7),
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
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (widget.playlist != null) ...[
                IconButton(
                  onPressed: _currentPlaylistIndex > 0 ? _playPrevious : null,
                  icon: Icon(
                    Icons.skip_previous,
                    size: 24,
                    color: colorController.textColor.value.withOpacity(0.6),
                  ),
                ),
              ],
              IconButton(
                onPressed: _isLoading ? null : _togglePlayPause,
                icon: _isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorController.primaryColor.value,
                        ),
                      )
                    : Icon(
                        _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        size: 32,
                        color: colorController.primaryColor.value,
                      ),
              ),
              if (widget.playlist != null) ...[
                IconButton(
                  onPressed: _currentPlaylistIndex < widget.playlist!.length - 1 ? _playNext : null,
                  icon: Icon(
                    Icons.skip_next,
                    size: 24,
                    color: colorController.textColor.value.withOpacity(0.6),
                  ),
                ),
              ] else ...[
                IconButton(
                  onPressed: _isLoading ? null : _stop,
                  icon: Icon(
                    Icons.stop_circle,
                    size: 24,
                    color: colorController.textColor.value.withOpacity(0.6),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}