import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/hymn/data/services/hymn_service.dart';
import 'package:fihirana/features/audio/data/services/audio_service.dart';
import 'package:fihirana/features/audio/data/services/local_audio_service.dart';
import 'package:fihirana/features/audio/presentation/widgets/modern_audio_player_widget.dart';

import 'package:fihirana/l10n/app_localizations.dart';

class AudioPlayerScreen extends StatefulWidget {
  final Hymn hymn;
  final List<Hymn>? playlist;
  final int? initialIndex;

  const AudioPlayerScreen({
    super.key,
    required this.hymn,
    this.playlist,
    this.initialIndex,
  });

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final HymnService _hymnService = HymnService();
  final AudioService _audioService = AudioService.instance;

  final LocalAudioService _localAudioService = LocalAudioService();
  late Hymn _currentHymn;
  List<Hymn> _playlist = [];
  int _currentIndex = 0;
  bool _autoPlayNext = false;
  final Map<String, double> _downloadProgress = <String, double>{};
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _currentHymn = widget.hymn;
    _currentIndex = widget.initialIndex ?? 0;
    _checkFavoriteStatus();
    _initializePlaylist();
  }

  Future<void> _checkFavoriteStatus() async {
    final isFav = await _hymnService.isHymnFavorite(_currentHymn.id);
    if (mounted) {
      setState(() {
        _isFavorite = isFav;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final l10n = AppLocalizations.of(context);
    try {
      await _hymnService.toggleFavorite(_currentHymn);
      _checkFavoriteStatus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorUpdatingFavorites)),
      );
    }
  }

  Future<void> _initializePlaylist() async {
    List<Hymn> initialList;
    if (widget.playlist != null) {
      initialList = widget.playlist!;
    } else {
      // Load all hymns as playlist
      try {
        initialList = await _hymnService.getAllHymns();
        if (kDebugMode) {
          print(
              'EnhancedAudioPlayer: Loaded ${initialList.length} total hymns');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error loading hymns: $e');
        }
        initialList = [];
      }
    }

    // Keep the full hymn library in the playlist.
    // AudioService will prefer local files when available and fall back to
    // remote audio for the rest.
    final filteredList = List<Hymn>.from(initialList);

    if (!filteredList.any((h) => h.id == widget.hymn.id)) {
      filteredList.insert(0, widget.hymn);
    }

    if (kDebugMode) {
      print(
          'EnhancedAudioPlayer: Final playlist has ${filteredList.length} hymns');
    }

    if (mounted) {
      setState(() {
        _playlist = filteredList;
        _currentIndex = filteredList.indexWhere(
          (hymn) => hymn.id == widget.hymn.id,
        );
        if (_currentIndex == -1 && filteredList.isNotEmpty) {
          _currentIndex = 0;
          _currentHymn = filteredList[0];
        }
      });

      // Set the playlist in AudioService for next/previous functionality
      if (filteredList.isNotEmpty) {
        final initialIndex = _currentIndex == -1 ? 0 : _currentIndex;
        _audioService.setPlaylist(filteredList, initialIndex);
      }
    }
  }

  void _onHymnChange(Hymn newHymn) {
    // Determine if we need to actually play the song or just update UI (if it's already playing)
    // But since this is usually called from user interaction (playlist tap),
    // we generally want to play it.

    setState(() {
      _currentHymn = newHymn;
      final newIndex = _playlist.indexWhere(
        (hymn) => hymn.id == newHymn.id,
      );
      if (newIndex != -1) {
        _currentIndex = newIndex;
      }
      _checkFavoriteStatus();
    });

    // Actually play the selected hymn
    _audioService.playHymn(newHymn);
  }

  void _onAutoPlayNextChange(bool value) {
    setState(() {
      _autoPlayNext = value;
    });
  }

  Future<void> _downloadAudioForHymn(Hymn hymn) async {
    final l10n = AppLocalizations.of(context);
    if (_hasLocalAudio(hymn)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.hymnAlreadyDownloaded)),
      );
      return;
    }

    if (_downloadProgress.containsKey(hymn.id)) return;

    setState(() {
      _downloadProgress[hymn.id] = 0.0;
    });

    try {
      final success = await _audioService.downloadAudioForHymn(
        hymn,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress[hymn.id] = progress;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _downloadProgress.remove(hymn.id);
        });
        if (success) {
          await _initializePlaylist();
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.downloadFailed)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadProgress.remove(hymn.id);
        });
      }
    }
  }

  bool _hasLocalAudio(Hymn hymn) {
    return _localAudioService.hasLocalAudio(hymn.id);
  }

  double? _getDownloadProgress(Hymn hymn) {
    return _downloadProgress[hymn.id];
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ColorController>(
      builder: (colorController) => Scaffold(
        body: ModernAudioPlayerWidget(
          hymn: _currentHymn,
          playlist: _playlist,
          onHymnChange: _onHymnChange,
          isFavorite: _isFavorite,
          onToggleFavorite: _toggleFavorite,
          autoPlayNext: _autoPlayNext,
          onAutoPlayNextChange: _onAutoPlayNextChange,
          onClose: () => Navigator.of(context).pop(),
          onDownload: _downloadAudioForHymn,
          isDownloaded: _hasLocalAudio,
          getDownloadProgress: _getDownloadProgress,
        ),
      ),
    );
  }
}

// Navigation helper
class AudioPlayerNavigator {
  static void navigateToEnhancedPlayer(
    BuildContext context, {
    required Hymn hymn,
    List<Hymn>? playlist,
    int? initialIndex,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AudioPlayerScreen(
          hymn: hymn,
          playlist: playlist,
          initialIndex: initialIndex,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  static void showEnhancedPlayerDialog(
    BuildContext context, {
    required Hymn hymn,
    List<Hymn>? playlist,
    int? initialIndex,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
            maxWidth: MediaQuery.of(context).size.width * 0.95,
          ),
          child: AudioPlayerScreen(
            hymn: hymn,
            playlist: playlist,
            initialIndex: initialIndex,
          ),
        ),
      ),
    );
  }
}
