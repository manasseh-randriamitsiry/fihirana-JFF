import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/audio/data/services/audio_service.dart';
import 'package:fihirana/features/audio/presentation/widgets/audio_cue.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/core/design_system/app_scale.dart';
import 'package:fihirana/core/design_system/app_surfaces.dart';
import 'package:fihirana/core/design_system/app_typography.dart';
import 'package:fihirana/core/design_system/components/app_sheet.dart';
import 'progress_slider.dart';

class CompactAudioPlayerWidget extends StatefulWidget {
  final Hymn hymn;
  final List<Hymn>? playlist;
  final Function(Hymn)? onHymnChange;
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
    _syncToLoadedHymn();
    if (widget.playlist != null) {
      _audioService.setPlaylist(widget.playlist!, _currentPlaylistIndex);
    }
    _initializePlayer();
  }

  @override
  void didUpdateWidget(CompactAudioPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hymn.id != oldWidget.hymn.id ||
        widget.playlist != oldWidget.playlist) {
      _syncToLoadedHymn();
      if (widget.playlist != null) {
        _audioService.setPlaylist(widget.playlist!, _currentPlaylistIndex);
      }
    }
  }

  /// This sheet is the now-playing window: it shows the hymn the player holds,
  /// and the page's hymn only while nothing is loaded. Seeding it from the page
  /// is what left the transport showing a play arrow over a running track.
  void _syncToLoadedHymn() {
    final loaded = _audioService.currentHymn;
    _currentDisplayedHymn = loaded ?? widget.hymn;

    _currentPlaylistIndex =
        _indexOf(loaded?.id) ?? _indexOf(widget.hymn.id) ?? 0;
  }

  int? _indexOf(String? id) {
    if (id == null) return null;
    final index = widget.playlist?.indexWhere((hymn) => hymn.id == id) ?? -1;
    return index < 0 ? null : index;
  }

  /// The hymn this sheet is the window onto: the one the player holds, or the
  /// page's while nothing is loaded.
  String get _displayedHymnId => _currentDisplayedHymn?.id ?? widget.hymn.id;

  void _initializePlayer() {
    _updateCurrentState();

    // Listen to current hymn changes
    _currentHymnSubscription =
        _audioService.currentPlayingHymnIdRx.listen((hymnId) {
      if (!mounted) return;

      final newCurrentHymn = _audioService.currentHymn;
      if (newCurrentHymn?.id != _currentDisplayedHymn?.id) {
        setState(() {
          _currentDisplayedHymn = newCurrentHymn ?? widget.hymn;
        });
        if (newCurrentHymn != null) {
          widget.onHymnChange?.call(newCurrentHymn);
        }
        _updatePlayingState();
      }
    });

    _playerStateSubscription = _audioService.playerStateStream.listen((state) {
      if (!mounted) return;

      // The sheet is the window onto the hymn the player holds. The id is
      // cleared the moment a track ends, so the loaded hymn - which is kept for
      // replay - is what a state change has to be matched against here.
      if (_audioService.currentHymn?.id != _displayedHymnId) return;

      final wasPlaying = _isPlaying;
      final isLoading = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;

      if (wasPlaying != state.playing || _isLoading != isLoading) {
        setState(() {
          _isPlaying = state.playing;
          _isLoading = isLoading;
        });
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
    if (_audioService.currentHymn?.id != _displayedHymnId) return;
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

  void _updatePlayingState() {
    if (!mounted) return;
    // Nothing loaded means nothing plays, whatever the last track was doing.
    final loaded = _audioService.currentHymn?.id == _displayedHymnId;
    final processing = _audioService.player.playerState.processingState;
    final nextIsPlaying = loaded && _audioService.isPlaying;
    final nextIsLoading = loaded &&
        (processing == ProcessingState.loading ||
            processing == ProcessingState.buffering);

    if (_isPlaying != nextIsPlaying || _isLoading != nextIsLoading) {
      setState(() {
        _isPlaying = nextIsPlaying;
        _isLoading = nextIsLoading;
      });
    }
  }

  Future<void> _playNext() async {
    if (_audioService.hasCue) {
      await _audioService.playNext();
      return;
    }
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
      if (_audioService.currentHymn?.id == _displayedHymnId) {
        // The player holds this hymn, so the button only pauses or resumes it.
        if (_isPlaying) {
          await _audioService.pause();
        } else {
          await _audioService.resume();
        }
      } else {
        // Nothing is loaded, so this is the first play of the hymn on screen.
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

  @override
  Widget build(BuildContext context) {
    final AppSurfaces s = AppSurfaces.of(context);
    final TextTheme type = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    final String title = _audioService.currentDisplayTitle.isNotEmpty
        ? _audioService.currentDisplayTitle
        : widget.hymn.title;
    final String number =
        _currentDisplayedHymn?.hymnNumber ?? widget.hymn.hymnNumber;

    return Container(
      // A modal sheet with a transparent barrier: this widget is the sheet, so
      // it carries the rounded top and the rule that closes it.
      decoration: BoxDecoration(
        color: s.sheet,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppScale.radiusSheet)),
        border: Border.all(color: s.ruleFirm, width: AppScale.ruleHair),
      ),
      clipBehavior: Clip.hardEdge,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppScale.space12),
                child: Container(
                    width: 40, height: AppScale.ruleBar, color: s.ruleFirm),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppScale.gutter, 0, AppScale.space4, AppScale.space12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: type.titleLarge?.copyWith(
                              color: s.ink, fontWeight: FontWeight.w700),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppScale.space4),
                        Text(
                          number,
                          style: AppTypography.figure(s,
                              size: AppScale.figureSm,
                              weight: FontWeight.w700,
                              color: s.muted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: () => Navigator.pop(context),
                    icon:
                        const Icon(Icons.close_rounded, size: AppScale.iconLg),
                    color: s.ink,
                    constraints: const BoxConstraints(
                        minWidth: AppScale.hitTarget,
                        minHeight: AppScale.hitTarget),
                  ),
                ],
              ),
            ),
            const AppRule(),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppScale.gutter,
                  AppScale.space16, AppScale.gutter, AppScale.space24),
              child: Column(
                children: [
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
                  const SizedBox(height: AppScale.space8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: l10n.previous,
                        onPressed: _playPrevious,
                        icon: const Icon(Icons.skip_previous_rounded,
                            size: AppScale.iconLg),
                        color: s.ink,
                        constraints: const BoxConstraints(
                            minWidth: AppScale.hitTarget,
                            minHeight: AppScale.hitTarget),
                      ),
                      const SizedBox(width: AppScale.space16),
                      FilledButton(
                        onPressed: _togglePlayPause,
                        style: FilledButton.styleFrom(
                          minimumSize:
                              const Size(AppScale.space64, AppScale.space64),
                          shape: const CircleBorder(),
                          padding: EdgeInsets.zero,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: AppScale.iconLg,
                                height: AppScale.iconLg,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                _isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: AppScale.space24,
                              ),
                      ),
                      const SizedBox(width: AppScale.space16),
                      IconButton(
                        tooltip: l10n.next,
                        onPressed: _playNext,
                        icon: const Icon(Icons.skip_next_rounded,
                            size: AppScale.iconLg),
                        color: s.ink,
                        constraints: const BoxConstraints(
                            minWidth: AppScale.hitTarget,
                            minHeight: AppScale.hitTarget),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildCueBlock(l10n),
          ],
        ),
      ),
    );
  }

  /// The queue this sheet can add to. The hymn offered is the one the page is
  /// reading, so the block only means something while the player holds a
  /// different one.
  Widget _buildCueBlock(AppLocalizations l10n) {
    return Obx(() {
      final playingId = _audioService.currentPlayingHymnIdRx.value;
      if (playingId.isEmpty || playingId == widget.hymn.id) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppRule(),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: AppScale.cuePeek),
            child: AudioCueList(
              actions: [
                TextButton(
                  onPressed: () => cueHymn(context, widget.hymn),
                  child: Text(l10n.add),
                ),
                if (_audioService.cueRx.isNotEmpty)
                  TextButton(
                    onPressed: _audioService.clearCue,
                    child: Text(l10n.clear),
                  ),
              ],
              onPlayNow: (hymn) {
                widget.onHymnChange?.call(hymn);
                _audioService.playHymn(hymn);
              },
            ),
          ),
        ],
      );
    });
  }
}
