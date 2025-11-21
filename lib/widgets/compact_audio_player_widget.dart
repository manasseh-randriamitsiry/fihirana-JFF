import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../models/hymn.dart';
import '../services/audio_service.dart';

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
    Key? key,
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
  }) : super(key: key);

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

  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;

  @override
  void initState() {
    super.initState();
    if (widget.playlist != null) {
      _currentPlaylistIndex = widget.playlist!.indexWhere(
        (hymn) => hymn.id == widget.hymn.id,
      );
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
      }
    }
  }

  void _initializePlayer() {
    _updateCurrentState();

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
      setState(() {
        _position = position;
      });
    });

    _durationSubscription = _audioService.durationStream.listen((duration) {
      if (!mounted) return;
      setState(() {
        _duration = duration;
      });
    });
  }

  void _updateCurrentState() {
    if (!mounted) return;
    final currentHymn = _audioService.currentHymn;
    if (currentHymn?.id == widget.hymn.id) {
      setState(() {
        _isPlaying = _audioService.isPlaying;
        _isLoading = false;
        _duration = _audioService.player.duration;
        _position = _audioService.player.position;
      });
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
                            widget.hymn.title,
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
                            'Hymn ${widget.hymn.hymnNumber}',
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
