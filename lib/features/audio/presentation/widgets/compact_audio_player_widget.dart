import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/audio/data/services/audio_service.dart';

class CompactAudioPlayerWidget extends StatefulWidget {
  final Hymn hymn;
  final List<Hymn>? playlist;
  final Function(Hymn)? onHymnChange;
  final bool autoPlayNext;
  final Function(bool)? onAutoPlayNextChange;
  final VoidCallback? onClose;
  final Function(Hymn)? onDownload;
  final bool Function(Hymn)? isDownloaded;
  final double? Function(Hymn)? getDownloadProgress;
  final VoidCallback? onToggleFavorite;

  const CompactAudioPlayerWidget({
    super.key,
    required this.hymn,
    this.playlist,
    this.onHymnChange,
    this.autoPlayNext = false,
    this.onAutoPlayNextChange,
    this.onClose,
    this.onDownload,
    this.isDownloaded,
    this.getDownloadProgress,
    this.onToggleFavorite,
  });

  @override
  State<CompactAudioPlayerWidget> createState() =>
      _CompactAudioPlayerWidgetState();
}

class _CompactAudioPlayerWidgetState extends State<CompactAudioPlayerWidget> {
  final AudioService _audioService = AudioService.instance;

  bool _isPlaying = false;
  bool _isLoading = false;
  Duration? _duration;
  Duration? _position;
  int _currentPlaylistIndex = 0;
  bool _isDraggingSlider = false;
  double _dragValue = 0.0;
  Hymn? _currentDisplayedHymn;

  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _currentHymnSubscription;

  @override
  void initState() {
    super.initState();
    _currentDisplayedHymn = widget.hymn;
    if (widget.playlist != null) {
      _currentPlaylistIndex = widget.playlist!.indexWhere(
        (hymn) => hymn.id == widget.hymn.id,
      );
      _audioService.setPlaylist(widget.playlist!, _currentPlaylistIndex);
    }
    _initializePlayer();
  }

  @override
  void didUpdateWidget(CompactAudioPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hymn.id != oldWidget.hymn.id ||
        widget.playlist != oldWidget.playlist) {
      if (widget.playlist != null) {
        _currentPlaylistIndex = widget.playlist!.indexWhere(
          (hymn) => hymn.id == widget.hymn.id,
        );
        _audioService.setPlaylist(widget.playlist!, _currentPlaylistIndex);
      }
    }
  }

  void _initializePlayer() {
    _updateCurrentState();

    // Listen to current hymn changes
    _currentHymnSubscription =
        _audioService.currentPlayingHymnIdRx.listen((hymnId) {
      if (!mounted) return;

      final newCurrentHymn = _audioService.currentHymn;
      if (newCurrentHymn?.id != _currentDisplayedHymn?.id) {
        setState(() {
          _currentDisplayedHymn = newCurrentHymn;
        });
        if (newCurrentHymn != null) {
          widget.onHymnChange?.call(newCurrentHymn);
        }
        _updatePlayingState();
      }
    });

    _playerStateSubscription = _audioService.playerStateStream.listen((state) {
      if (!mounted) return;

      // Always update state if this is the currently displayed hymn or if no hymn is displayed yet
      final currentHymnId = _audioService.currentPlayingHymnId;
      final displayedHymnId = _currentDisplayedHymn?.id;
      final widgetHymnId = widget.hymn.id;

      // Update state if current playing hymn matches our widget or displayed hymn
      if (currentHymnId == displayedHymnId ||
          currentHymnId == widgetHymnId ||
          displayedHymnId == null) {
        final wasPlaying = _isPlaying;
        final isLoading = state.processingState == ProcessingState.loading ||
            state.processingState == ProcessingState.buffering;

        if (wasPlaying != state.playing || _isLoading != isLoading) {
          setState(() {
            _isPlaying = state.playing;
            _isLoading = isLoading;
          });
        }

        if (state.processingState == ProcessingState.completed &&
            widget.autoPlayNext &&
            widget.playlist != null) {
          _playNext();
        }
      }
    });

    _positionSubscription = _audioService.positionStream.listen((position) {
      if (!mounted || _isDraggingSlider) return;
      final positionValue = position;
      if (positionValue == null) return;
      final currentPosition = _position;
      if (currentPosition == null) {
        setState(() {
          _position = positionValue;
        });
        return;
      }

      final positionMillis = positionValue.inMilliseconds;
      final currentPositionMillis = currentPosition.inMilliseconds;
      if ((positionMillis - currentPositionMillis).abs() >= 500) {
        setState(() {
          _position = positionValue;
        });
      }
    });

    _durationSubscription = _audioService.durationStream.listen((duration) {
      if (!mounted) return;
      if (_duration != duration) {
        setState(() {
          _duration = duration;
        });
      }
    });
  }

  void _updateCurrentState() {
    if (!mounted) return;
    final currentHymn = _audioService.currentHymn;
    if (currentHymn?.id == _currentDisplayedHymn?.id ||
        _currentDisplayedHymn == null) {
      final nextDuration = _audioService.player.duration;
      final nextPosition = _audioService.player.position;
      if (_isPlaying != _audioService.isPlaying ||
          _duration != nextDuration ||
          _position != nextPosition ||
          _isLoading) {
        setState(() {
          _isPlaying = _audioService.isPlaying;
          _isLoading = false;
          _duration = nextDuration;
          _position = nextPosition;
        });
      }
    }
  }

  void _updatePlayingState() {
    if (!mounted) return;
    final currentHymnId = _audioService.currentPlayingHymnId;
    final displayedHymnId = _currentDisplayedHymn?.id;
    final widgetHymnId = widget.hymn.id;

    // Update playing state if this matches current playing hymn
    if (currentHymnId == displayedHymnId || currentHymnId == widgetHymnId) {
      final nextIsLoading = _audioService.player.playerState.processingState ==
              ProcessingState.loading ||
          _audioService.player.playerState.processingState ==
              ProcessingState.buffering;
      if (_isPlaying != _audioService.isPlaying ||
          _isLoading != nextIsLoading) {
        setState(() {
          _isPlaying = _audioService.isPlaying;
          _isLoading = nextIsLoading;
        });
      }
    }
  }

  Future<void> _playNext() async {
    if (widget.playlist == null || widget.playlist!.isEmpty) return;
    final nextIndex = (_currentPlaylistIndex + 1) % widget.playlist!.length;
    final nextHymn = widget.playlist![nextIndex];
    widget.onHymnChange?.call(nextHymn);
    await _audioService.playHymn(nextHymn);
  }

  Future<void> _playPrevious() async {
    if (widget.playlist == null || widget.playlist!.isEmpty) return;
    final prevIndex = _currentPlaylistIndex == 0
        ? widget.playlist!.length - 1
        : _currentPlaylistIndex - 1;
    final prevHymn = widget.playlist![prevIndex];
    widget.onHymnChange?.call(prevHymn);
    await _audioService.playHymn(prevHymn);
  }

  Future<void> _togglePlayPause() async {
    try {
      final currentHymnId = _audioService.currentPlayingHymnId;
      final displayedHymnId = _currentDisplayedHymn?.id;
      final widgetHymnId = widget.hymn.id;

      if (currentHymnId == displayedHymnId || currentHymnId == widgetHymnId) {
        // Same hymn is playing, toggle play/pause
        if (_isPlaying) {
          await _audioService.pause();
        } else {
          await _audioService.resume();
        }
      } else {
        // Different hymn, start playing the current one
        setState(() {
          _isLoading = true;
        });
        await _audioService.playHymn(_currentDisplayedHymn ?? widget.hymn);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isPlaying = false;
        });
      }
    }
  }

  Future<void> _seekTo(double value) async {
    if (_duration != null) {
      final position =
          Duration(milliseconds: (value * _duration!.inMilliseconds).round());
      await _audioService.seekTo(position);
    }
    setState(() {
      _isDraggingSlider = false;
    });
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _currentHymnSubscription?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    // Dark theme colors
    const backgroundColor = Color(0xFF1C1B1F);
    const primaryTextColor = Colors.white;
    const secondaryTextColor = Colors.white70;

    return Container(
      decoration: const BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Title, Number, Favorite
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _audioService.currentDisplayTitle.isNotEmpty
                                ? _audioService.currentDisplayTitle
                                : widget.hymn.title,
                            style: const TextStyle(
                              color: primaryTextColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _audioService.currentDisplaySubtitle.isNotEmpty
                                ? _audioService.currentDisplaySubtitle
                                : 'Hymn ${widget.hymn.hymnNumber}',
                            style: const TextStyle(
                              color: secondaryTextColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Controls Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded,
                          color: Colors.white, size: 36),
                      onPressed: _playPrevious,
                    ),
                    GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: _isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 3,
                                ),
                              )
                            : Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.black,
                                size: 32,
                              ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded,
                          color: Colors.white, size: 36),
                      onPressed: _playNext,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Slider and Time
                Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: Colors.white,
                        trackHeight: 2,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 14),
                      ),
                      child: Slider(
                        value: _isDraggingSlider
                            ? _dragValue
                            : (_duration != null &&
                                    _position != null &&
                                    _duration!.inMilliseconds > 0)
                                ? (_position!.inMilliseconds.toDouble() /
                                        _duration!.inMilliseconds.toDouble())
                                    .clamp(0.0, 1.0)
                                : 0.0,
                        onChanged: (value) {
                          setState(() {
                            _isDraggingSlider = true;
                            _dragValue = value;
                          });
                        },
                        onChangeEnd: _seekTo,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_isDraggingSlider
                                ? Duration(
                                    milliseconds: (_dragValue *
                                            (_duration?.inMilliseconds ?? 0))
                                        .round())
                                : _position ?? Duration.zero),
                            style: const TextStyle(
                                color: secondaryTextColor, fontSize: 12),
                          ),
                          Text(
                            _formatDuration(_duration ?? Duration.zero),
                            style: const TextStyle(
                                color: secondaryTextColor, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
