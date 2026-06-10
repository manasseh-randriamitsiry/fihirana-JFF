import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/audio/data/services/audio_service.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'player_top_bar.dart';
import 'album_art_card.dart';
import 'song_info_section.dart';
import 'progress_slider.dart';
import 'player_controls.dart';
import 'playlist_bottom_sheet.dart';

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
  Hymn? _currentDisplayedHymn;

  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _playlistChangeSubscription;
  StreamSubscription? _currentHymnSubscription;

  @override
  void initState() {
    super.initState();
    _currentDisplayedHymn = widget.hymn;
    _initializePlayer();
  }

  @override
  void didUpdateWidget(ModernAudioPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // No need to manage playlist index locally anymore
  }

  void _initializePlayer() {
    _updateCurrentState();

    // Listen to current hymn changes (only for regular hymns, not recordings)
    _currentHymnSubscription =
        _audioService.currentPlayingHymnIdRx.listen((hymnId) {
      if (!mounted) return;

      final newCurrentHymn = _audioService.currentHymn;
      // Only update if this is a regular hymn (not a recording) and different from current
      if (newCurrentHymn != null &&
          !newCurrentHymn.id.startsWith('recording_') &&
          newCurrentHymn.id != _currentDisplayedHymn?.id) {
        setState(() {
          _currentDisplayedHymn = newCurrentHymn;
        });
        // Notify parent of change
        widget.onHymnChange?.call(newCurrentHymn);
      }
    });

    _playerStateSubscription = _audioService.playerStateStream.listen((state) {
      if (!mounted) return;

      // Only respond to state changes for regular hymns, not recordings
      final currentHymn = _audioService.currentHymn;
      if (currentHymn != null &&
          !currentHymn.id.startsWith('recording_') &&
          currentHymn.id == _currentDisplayedHymn?.id) {
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
        if (state.processingState == ProcessingState.idle &&
            !currentHymn.id.startsWith('recording_') &&
            currentHymn.id == _currentDisplayedHymn?.id) {
          setState(() {
            _isLoading = false;
            _isPlaying = false;
          });
        }
      }
    });

    _positionSubscription = _audioService.positionStream.listen((position) {
      if (!mounted || _isDraggingSlider) return;
      final currentHymn = _audioService.currentHymn;
      if (currentHymn != null && !currentHymn.id.startsWith('recording_')) {
        if (_position != position) {
          setState(() {
            _position = position;
          });
        }
      }
    });

    _durationSubscription = _audioService.durationStream.listen((duration) {
      if (!mounted) return;
      final currentHymn = _audioService.currentHymn;
      if (currentHymn != null && !currentHymn.id.startsWith('recording_')) {
        if (_duration != duration) {
          setState(() {
            _duration = duration;
          });
        }
      }
    });

    _playlistChangeSubscription =
        _audioService.playlistChangeNotifier.listen((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  void _updateCurrentState() {
    if (!mounted) return;
    final currentHymn = _audioService.currentHymn;
    // Only update state for regular hymns, not recordings
    if (currentHymn != null &&
        !currentHymn.id.startsWith('recording_') &&
        currentHymn.id == _currentDisplayedHymn?.id) {
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
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorPlayingNextHymn(e.toString()))),
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
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorPlayingPreviousHymn(e.toString()))),
        );
      }
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      final currentHymn = _audioService.currentHymn;
      // Only handle play/pause for regular hymns, not recordings
      if (currentHymn != null &&
          !currentHymn.id.startsWith('recording_') &&
          currentHymn.id == _currentDisplayedHymn?.id) {
        if (_isPlaying) {
          await _audioService.pause();
        } else {
          await _audioService.resume();
        }
      } else {
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
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorPlayingAudio(e.toString()))),
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
    _currentHymnSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dark theme colors based on the image
    const backgroundColor = Color(0xFF1C1B1F); // Dark background

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
                PlayerTopBar(onClose: widget.onClose),

                const SizedBox(height: 20),

                // Album Art Card
                Expanded(
                  flex: 5,
                  child: AlbumArtCard(
                    hymnNumber: _currentDisplayedHymn?.hymnNumber ??
                        widget.hymn.hymnNumber,
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
                        SongInfoSection(
                          title:
                              _currentDisplayedHymn?.title ?? widget.hymn.title,
                          hymnNumber: _currentDisplayedHymn?.hymnNumber ??
                              widget.hymn.hymnNumber,
                          isFavorite: widget.isFavorite,
                          onToggleFavorite: widget.onToggleFavorite,
                        ),

                        const SizedBox(height: 30),

                        // Progress Slider
                        ProgressSlider(
                          duration: _duration,
                          position: _position,
                          isDragging: _isDraggingSlider,
                          dragValue: _dragValue,
                          onChanged: (value) {
                            setState(() {
                              _isDraggingSlider = true;
                              _dragValue = value;
                            });
                          },
                          onChangeEnd: _seekTo,
                        ),

                        const SizedBox(height: 20),

                        // Main Controls
                        PlayerControls(
                          isPlaying: _isPlaying,
                          isLoading: _isLoading,
                          autoPlayNext: widget.autoPlayNext,
                          onAutoPlayNextChange: widget.onAutoPlayNextChange,
                          onPlayPrevious: _playPrevious,
                          onTogglePlayPause: _togglePlayPause,
                          onPlayNext: _playNext,
                          onShowPlaylist: () => _showPlaylist(context),
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
        return PlaylistBottomSheet(
          playlist: widget.playlist,
          currentHymn: _currentDisplayedHymn,
          onHymnChange: widget.onHymnChange,
          onDownload: widget.onDownload,
          isDownloaded: widget.isDownloaded,
          getDownloadProgress: widget.getDownloadProgress,
        );
      },
    );
  }
}
