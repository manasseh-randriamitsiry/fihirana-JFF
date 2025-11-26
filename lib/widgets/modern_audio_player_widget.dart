import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../models/hymn.dart';
import '../services/audio_service.dart';

class ModernAudioPlayerWidget extends StatefulWidget {
  final Hymn hymn;
  final List<Hymn>? playlist;
  final Function(Hymn)? onHymnChange;
  final bool autoPlayNext;
  final Function(bool)? onAutoPlayNextChange;
  final VoidCallback? onClose;
  final Function(Hymn)? onDownload;
  final bool Function(Hymn)? isDownloaded;
  final double? Function(Hymn)? getDownloadProgress;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  const ModernAudioPlayerWidget({
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
    this.isFavorite = false,
    this.onToggleFavorite,
  });

  @override
  State<ModernAudioPlayerWidget> createState() =>
      _ModernAudioPlayerWidgetState();
}

class _ModernAudioPlayerWidgetState extends State<ModernAudioPlayerWidget> {
  final AudioService _audioService = AudioService.instance;

  bool _isPlaying = false;
  bool _isLoading = false;
  Duration? _duration;
  Duration? _position;
  bool _isDraggingSlider = false;
  double _dragValue = 0.0;

  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _playlistChangeSubscription;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(ModernAudioPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // No need to manage playlist index locally anymore
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

    // Listen to playlist changes
    _playlistChangeSubscription = _audioService.playlistChangeNotifier.listen((_) {
      if (!mounted) return;
      // Update UI when playlist changes
      setState(() {});
    });

    // Listen to player errors via playerStateStream
    _audioService.playerStateStream.listen((state) {
      if (!mounted) return;
      
      // Handle error states
      if (state.processingState == ProcessingState.idle && 
          _audioService.currentHymn?.id == widget.hymn.id) {
        setState(() {
          _isLoading = false;
          _isPlaying = false;
        });
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
        _duration = _audioService.player.duration;
        _position = _audioService.player.position;
      });
    }
  }

  Future<void> _playNext() async {
    // Use AudioService's playlist management instead of local
    try {
      await _audioService.playNext();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing next hymn: $e')),
        );
      }
    }
  }

  Future<void> _playPrevious() async {
    // Use AudioService's playlist management instead of local
    try {
      await _audioService.playPrevious();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing previous hymn: $e')),
        );
      }
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_audioService.currentHymn?.id == widget.hymn.id) {
        if (_isPlaying) {
          await _audioService.pause();
        } else {
          await _audioService.resume();
        }
      } else {
        setState(() {
          _isLoading = true;
        });
        await _audioService.playHymn(widget.hymn);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isPlaying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing audio: $e')),
        );
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
    _playlistChangeSubscription?.cancel();
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
    // Dark theme colors based on the image
    const backgroundColor = Color(0xFF1C1B1F); // Dark background
    const cardColor = Color(0xFFE0C09C); // Beige/Gold card color from image
    const primaryTextColor = Colors.white;
    const secondaryTextColor = Colors.white70;

    return Container(
      color: backgroundColor,
      child: Stack(
        children: [
          // Background Gradient (Subtle)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2E2B33),
                  Color(0xFF121212),
                ],
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down,
                            color: Colors.white, size: 30),
                        onPressed:
                            widget.onClose ?? () => Navigator.of(context).pop(),
                      ),
                      Text(
                        'Now Playing',
                        style: TextStyle(
                          color: primaryTextColor.withValues(alpha:0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_horiz, color: Colors.white),
                        onPressed: () => _showPlaylist(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Album Art Card
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha:0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Placeholder for Hymn Image (or just the color/gradient)
                          Center(
                            child: Icon(
                              Icons.music_note,
                              size: 120,
                              color: Colors.brown.withValues(alpha:0.3),
                            ),
                          ),
                          // Hymn Number Overlay
                          Positioned(
                            top: 20,
                            right: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha:0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '#${widget.hymn.hymnNumber}',
                                style: TextStyle(
                                  color: Colors.brown.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Song Info & Controls
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Heart
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.hymn.title,
                                    style: const TextStyle(
                                      color: primaryTextColor,
                                      fontSize: 24,
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
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white24, width: 1),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  widget.isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: widget.isFavorite
                                      ? Colors.red
                                      : Colors.white,
                                ),
                                onPressed: widget.onToggleFavorite,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // Progress Slider
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.white,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: Colors.white,
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14),
                          ),
                          child: Slider(
                            value: _isDraggingSlider
                                ? _dragValue
                                : (_duration != null &&
                                        _position != null &&
                                        _duration!.inMilliseconds > 0)
                                    ? (_position!.inMilliseconds.toDouble() /
                                            _duration!.inMilliseconds
                                                .toDouble())
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

                        // Time Indicators
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(_isDraggingSlider
                                    ? Duration(
                                        milliseconds: (_dragValue *
                                                (_duration?.inMilliseconds ??
                                                    0))
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

                        const SizedBox(height: 20),

                        // Main Controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Previous (30 Sec Back style)
                            IconButton(
                              icon: const Icon(Icons.skip_previous_rounded,
                                  color: Colors.white, size: 32),
                              onPressed: _playPrevious,
                            ),

                            // Play/Pause (Large White Circle)
                            GestureDetector(
                              onTap: _togglePlayPause,
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: _isLoading
                                    ? const Padding(
                                        padding: EdgeInsets.all(20),
                                        child: CircularProgressIndicator(
                                          color: Colors.black,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : Icon(
                                        _isPlaying
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        color: Colors.black,
                                        size: 36,
                                      ),
                              ),
                            ),

                            // Next (30 Sec Forward style)
                            IconButton(
                              icon: const Icon(Icons.skip_next_rounded,
                                  color: Colors.white, size: 32),
                              onPressed: _playNext,
                            ),
                          ],
                        ),

                        // Bottom Actions (Shuffle/Repeat/List)
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Autoplay Toggle
                            Row(
                              children: [
                                Text(
                                  'Autoplay',
                                  style: TextStyle(
                                    color: widget.autoPlayNext
                                        ? Colors.white
                                        : Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                                Switch(
                                  value: widget.autoPlayNext,
                                  onChanged: widget.onAutoPlayNextChange,
                                  activeThumbColor: Colors.white,
                                  activeTrackColor: Colors.white24,
                                  inactiveThumbColor: Colors.white54,
                                  inactiveTrackColor: Colors.white10,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPlaylist(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1B1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Playlist',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white24),
                  Expanded(
                    child: widget.playlist == null || widget.playlist!.isEmpty
                        ? const Center(
                            child: Text(
                              'No hymns in playlist',
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                        : ListView.builder(
                            itemCount: widget.playlist!.length,
                            itemBuilder: (context, index) {
                              final hymn = widget.playlist![index];
                              final isCurrent = hymn.id == widget.hymn.id;
                              final isDownloaded =
                                  widget.isDownloaded?.call(hymn) ?? false;
                              final downloadProgress =
                                  widget.getDownloadProgress?.call(hymn);

                              return ListTile(
                                selected: isCurrent,
                                selectedTileColor: Colors.white10,
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? Colors.white
                                        : Colors.white10,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: isCurrent
                                        ? const Icon(Icons.bar_chart,
                                            color: Colors.black, size: 20)
                                        : Text(
                                            hymn.hymnNumber,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                                title: Text(
                                  hymn.title,
                                  style: TextStyle(
                                    color: isCurrent
                                        ? Colors.white
                                        : Colors.white70,
                                    fontWeight: isCurrent
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  'Hymn ${hymn.hymnNumber}',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (downloadProgress != null)
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          value: downloadProgress,
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    else if (isDownloaded)
                                      const Icon(Icons.check_circle,
                                          color: Colors.green, size: 20)
                                    else
                                      IconButton(
                                        icon: const Icon(Icons.download_rounded,
                                            color: Colors.white54),
                                        onPressed: () {
                                          widget.onDownload?.call(hymn);
                                          setState(
                                              () {}); // Refresh to show progress if immediate
                                        },
                                      ),
                                  ],
                                ),
                                onTap: () {
                                  widget.onHymnChange?.call(hymn);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
