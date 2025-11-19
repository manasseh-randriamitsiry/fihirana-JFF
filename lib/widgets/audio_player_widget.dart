import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/hymn.dart';
import '../services/audio_service.dart';

class AudioPlayerWidget extends StatefulWidget {
  final Hymn hymn;
  final List<Hymn>? playlist;
  final Function(Hymn)? onHymnChange;
  final bool autoPlayNext;
  final Function(bool)? onAutoPlayNextChange;

  const AudioPlayerWidget({
    super.key,
    required this.hymn,
    this.playlist,
    this.onHymnChange,
    this.autoPlayNext = false,
    this.onAutoPlayNextChange,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioService _audioService = AudioService.instance;
  bool _isLoading = false;
  Duration? _duration;
  Duration? _position;
  bool _isPlaying = false;
  bool _autoPlayNext = false;
  int _currentPlaylistIndex = 0;
  bool _isSeeking = false;

  @override
  void initState() {
    super.initState();
    _autoPlayNext = widget.autoPlayNext;
    _initializePlayer();
    
    if (widget.playlist != null) {
      _currentPlaylistIndex = widget.playlist!.indexWhere(
        (hymn) => hymn.id == widget.hymn.id,
      );
    }
  }

  void _initializePlayer() {
    _updateCurrentState();
    
    _audioService.playerStateStream.listen((state) {
      if (mounted) {
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
          // ULTRA-AGGRESSIVE VALIDATION: Reject extremely large positions immediately
          const absoluteMaxPosition = 600000000; // 10 minutes in milliseconds
          if (position.inMilliseconds > absoluteMaxPosition) {
            print('AudioPlayerWidget: Rejecting extremely large position: ${position.inMilliseconds}ms (max: $absoluteMaxPosition)');
            if (mounted) {
              setState(() {
                _position = Duration.zero;
              });
            }
            return; // Completely ignore this position update
          }
          
          // Additional validation: position should not be unreasonably large
          if (_duration != null && position.inMilliseconds > _duration!.inMilliseconds * 2.0) {
            print('AudioPlayerWidget: Ignoring unreasonable position: ${position.inMilliseconds}ms vs duration: ${_duration!.inMilliseconds}ms');
            if (mounted) {
              setState(() {
                _position = Duration.zero;
              });
            }
            return; // Ignore this position update
          }
          
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
    
    // ULTRA-AGGRESSIVE FIX: Multiple validation layers
    // 1. Basic sanity check
    if (positionMs < 0 || durationMs <= 0) {
      if (mounted) {
        setState(() {
          _position = Duration.zero;
        });
      }
      return 0.0;
    }
    
    // 2. Reasonable position check (position should not exceed duration by more than 10 seconds)
    final maxReasonablePosition = durationMs + 10000; // +10 seconds buffer
    if (positionMs > maxReasonablePosition) {
      print('AudioPlayerWidget: Position ($positionMs) exceeds reasonable max ($maxReasonablePosition) - resetting to 0.0');
      if (mounted) {
        setState(() {
          _position = Duration.zero;
        });
      }
      return 0.0;
    }
    
    // 3. Absolute maximum cap (prevent any extremely large values)
    const absoluteMaxPosition = 600000000; // 10 minutes in milliseconds
    if (positionMs > absoluteMaxPosition) {
      print('AudioPlayerWidget: Position ($positionMs) exceeds absolute max ($absoluteMaxPosition) - resetting to 0.0');
      if (mounted) {
        setState(() {
          _position = Duration.zero;
        });
      }
      return 0.0;
    }
    
    // 4. Duration-based cap (position should not be more than 3x duration)
    if (positionMs > durationMs * 3.0) {
      print('AudioPlayerWidget: Position ($positionMs) > 3x duration ($durationMs) - resetting to 0.0');
      if (mounted) {
        setState(() {
          _position = Duration.zero;
        });
      }
      return 0.0;
    }
    
    final value = positionMs / durationMs;
    final clampedValue = value.clamp(0.0, 1.0);
    
    // Debug logging for troubleshooting
    if (clampedValue != value) {
      print('AudioPlayerWidget: Clamped slider value from $value to $clampedValue (pos: $positionMs, dur: $durationMs)');
    }
    
    return clampedValue;
  }

  double _getSafeSliderValue() {
    try {
      final calculatedValue = _calculateSliderValue();
      // Final safety check - ensure value is within valid range
      return calculatedValue.clamp(0.0, 1.0);
    } catch (e) {
      print('AudioPlayerWidget: Error calculating slider value: $e, returning 0.0');
      return 0.0;
    }
  }

  Future<void> _seekTo(double value) async {
    if (_duration == null || 
        _audioService.currentHymn?.id != widget.hymn.id || 
        _isSeeking || 
        _isLoading) {
      return;
    }
    
    _isSeeking = true;
    
    try {
      final clampedValue = value.clamp(0.0, 1.0);
      final position = Duration(milliseconds: (clampedValue * _duration!.inMilliseconds).round());
      
      print('AudioPlayerWidget: Seeking to ${position.inSeconds}s (${(clampedValue * 100).toStringAsFixed(1)}%)');
      await _audioService.seekTo(position);
    } catch (e) {
      print('AudioPlayerWidget: Seek error: $e');
    } finally {
      _isSeeking = false;
    }
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            widget.hymn.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Hymn ${widget.hymn.hymnNumber}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
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
                          ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _autoPlayNext ? Icons.play_circle : Icons.playlist_play,
                          size: 14,
                          color: _autoPlayNext
                              ? Theme.of(context).primaryColor
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _autoPlayNext ? 'Auto' : 'Single',
                          style: TextStyle(
                            fontSize: 12,
                            color: _autoPlayNext
                                ? Theme.of(context).primaryColor
                                : Colors.grey[600],
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
          const SizedBox(height: 16),
          Row(
            children: [
              Text(_formatDuration(_position)),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _getSafeSliderValue(),
                    onChanged: (_duration != null && !_isLoading && !_isSeeking && _audioService.currentHymn?.id == widget.hymn.id) ? _seekTo : null,
                    min: 0.0,
                    max: 1.0,
                  ),
                ),
              ),
              Text(_formatDuration(_duration)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (widget.playlist != null) ...[
                IconButton(
                  onPressed: _currentPlaylistIndex > 0 ? _playPrevious : null,
                  icon: const Icon(
                    Icons.skip_previous,
                    size: 36,
                    color: Colors.grey,
                  ),
                ),
              ],
              IconButton(
                onPressed: _isLoading ? null : _togglePlayPause,
                icon: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        size: 48,
                        color: Theme.of(context).primaryColor,
                      ),
              ),
              if (widget.playlist != null) ...[
                IconButton(
                  onPressed: _currentPlaylistIndex < widget.playlist!.length - 1 ? _playNext : null,
                  icon: const Icon(
                    Icons.skip_next,
                    size: 36,
                    color: Colors.grey,
                  ),
                ),
              ] else ...[
                IconButton(
                  onPressed: _isLoading ? null : _stop,
                  icon: const Icon(
                    Icons.stop_circle,
                    size: 36,
                    color: Colors.grey,
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