import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:get/get.dart';
import '../../controller/color_controller.dart';
import '../../models/hymn.dart';
import '../../services/hymn_service.dart';
import '../../services/audio_service.dart';
import '../../services/audio_file_mapping.dart';
import '../../services/local_audio_service.dart';
import '../../widgets/lightweight_audio_player_widget.dart';
import '../../l10n/app_localizations.dart';

class EnhancedAudioPlayerScreen extends StatefulWidget {
  final Hymn hymn;
  final List<Hymn>? playlist;
  final int? initialIndex;

  const EnhancedAudioPlayerScreen({
    Key? key,
    required this.hymn,
    this.playlist,
    this.initialIndex,
  }) : super(key: key);

  @override
  State<EnhancedAudioPlayerScreen> createState() =>
      _EnhancedAudioPlayerScreenState();
}

class _EnhancedAudioPlayerScreenState extends State<EnhancedAudioPlayerScreen> {
  final ColorController _colorController = Get.find<ColorController>();
  final HymnService _hymnService = HymnService();
  final AudioService _audioService = AudioService.instance;
  final LocalAudioService _localAudioService = LocalAudioService();
  late Hymn _currentHymn;
  List<Hymn> _playlist = [];
  int _currentIndex = 0;
  bool _autoPlayNext = false;
  bool _isLoadingPlaylist = true;
  final Map<String, double> _downloadProgress =
      <String, double>{}; // Track download progress

  @override
  void initState() {
    super.initState();
    _currentHymn = widget.hymn;
    _currentIndex = widget.initialIndex ?? 0;
    _initializePlaylist();
  }

  Future<void> _initializePlaylist() async {
    setState(() {
      _isLoadingPlaylist = true;
    });

    List<Hymn> initialList;
    if (widget.playlist != null) {
      initialList = widget.playlist!;
    } else {
      // Load all hymns as playlist
      try {
        initialList = await _hymnService.getAllHymns();
        print('EnhancedAudioPlayer: Loaded ${initialList.length} total hymns');
      } catch (e) {
        print('Error loading hymns: $e');
        initialList = [];
      }
    }

    // Create playlist of hymns that have audio (local or remote)
    print('EnhancedAudioPlayer: Creating playlist of hymns with audio');

    final audioMapping = AudioFileMapping();

    // Ensure mapping is up to date
    if (audioMapping.isCacheExpired()) {
      print('EnhancedAudioPlayer: Audio mapping expired, updating...');
      await audioMapping.updateAudioFileMapping();
    }

    // Get local audio files
    await _localAudioService.initialize();
    final localHymnIds = await _localAudioService.getLocalHymnIds();
    final remoteAudioFiles = audioMapping.getAllAudioFiles();

    // Combine local and remote audio availability
    final allAvailableHymnIds = <String>{};
    allAvailableHymnIds.addAll(localHymnIds);
    allAvailableHymnIds.addAll(remoteAudioFiles.keys);

    final audioCount = allAvailableHymnIds.length;
    print(
        'EnhancedAudioPlayer: Found $audioCount hymns with audio (${localHymnIds.length} local, ${remoteAudioFiles.length} remote)');

    // Debug: Print sample info
    print(
        'EnhancedAudioPlayer: Sample local hymn IDs: ${localHymnIds.take(5).toList()}');
    print(
        'EnhancedAudioPlayer: Sample remote audio files: ${remoteAudioFiles.entries.take(5).toList()}');
    print('EnhancedAudioPlayer: Current hymn ID: ${widget.hymn.id}');
    print(
        'EnhancedAudioPlayer: Current hymn has local audio: ${localHymnIds.contains(widget.hymn.id)}');

    // Create playlist by matching hymns with available audio files
    final filteredList = <Hymn>[];

    for (final hymn in initialList) {
      if (allAvailableHymnIds.contains(hymn.id)) {
        filteredList.add(hymn);
        print('EnhancedAudioPlayer: Added hymn ${hymn.id} to playlist');
      }
    }

    // Always include current hymn even if not in audio files (to avoid empty screen)
    if (!filteredList.any((h) => h.id == widget.hymn.id)) {
      filteredList.insert(0, widget.hymn);
      print(
          'EnhancedAudioPlayer: Added current hymn ${widget.hymn.id} at beginning of playlist');
    }

    print(
        'EnhancedAudioPlayer: Final playlist has ${filteredList.length} hymns');

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
        _isLoadingPlaylist = false;
      });
    }
  }

  void _onHymnChange(Hymn newHymn) {
    setState(() {
      _currentHymn = newHymn;
      final newIndex = _playlist.indexWhere(
        (hymn) => hymn.id == newHymn.id,
      );
      if (newIndex != -1) {
        _currentIndex = newIndex;
      }
    });
  }

  void _onAutoPlayNextChange(bool value) {
    setState(() {
      _autoPlayNext = value;
    });
  }

  Future<void> _downloadAudioForHymn(Hymn hymn) async {
    // Check if already downloaded
    if (_hasLocalAudio(hymn)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This hymn is already downloaded!'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Check if already downloading
    if (_downloadProgress.containsKey(hymn.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This hymn is already downloading!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Initialize progress
    setState(() {
      _downloadProgress[hymn.id] = 0.0;
    });

    try {
      // Download with progress callback
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Downloaded ${hymn.title}!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          // Refresh playlist to update download status
          await _initializePlaylist();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Download failed. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadProgress.remove(hymn.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  bool _hasLocalAudio(Hymn hymn) {
    return _localAudioService.hasLocalAudio(hymn.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GetBuilder<ColorController>(
      builder: (colorController) => NeumorphicTheme(
        themeMode: colorController.themeMode,
        theme: colorController.getNeumorphicLightTheme(),
        darkTheme: colorController.getNeumorphicDarkTheme(),
        child: Scaffold(
          backgroundColor: colorController.backgroundColor.value,
          appBar: AppBar(
            backgroundColor: colorController.backgroundColor.value,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            title: Text(
              'Audio Player',
              style: TextStyle(
                color: colorController.textColor.value,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Enhanced audio player
                LightweightAudioPlayerWidget(
                  hymn: _currentHymn,
                  playlist: _playlist,
                  autoPlayNext: _autoPlayNext,
                  onHymnChange: _onHymnChange,
                  onAutoPlayNextChange: _onAutoPlayNextChange,
                ),

                const SizedBox(height: 24),

                // Playlist section
                if (_isLoadingPlaylist)
                  Center(
                    child: CircularProgressIndicator(
                      color: colorController.primaryColor.value,
                    ),
                  )
                else if (_playlist.isNotEmpty)
                  Column(
                    children: [
                      _buildPlaylistSection(),
                      const SizedBox(height: 16),
                      _buildLocalAudioSection(),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistSection() {
    return Neumorphic(
      style: NeumorphicStyle(
        depth: 4,
        intensity: 0.8,
        color: _colorController.backgroundColor.value,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Playlist',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _colorController.textColor.value,
                      ),
                    ),
                    Text(
                      '${_currentIndex + 1} / ${_playlist.length}',
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            _colorController.textColor.value.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Autoplay',
                      style: TextStyle(
                        fontSize: 12,
                        color: _colorController.textColor.value,
                      ),
                    ),
                    const SizedBox(width: 8),
                    NeumorphicSwitch(
                      value: _autoPlayNext,
                      style: NeumorphicSwitchStyle(
                        activeTrackColor: _colorController.primaryColor.value,
                        inactiveTrackColor:
                            _colorController.backgroundColor.value,
                      ),
                      onChanged: _onAutoPlayNextChange,
                      height: 24,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 500,
              child: ListView.builder(
                itemCount: _playlist.length,
                itemBuilder: (context, index) {
                  final hymn = _playlist[index];
                  final isCurrentHymn = hymn.id == _currentHymn.id;

                  return NeumorphicButton(
                    style: NeumorphicStyle(
                      depth: isCurrentHymn ? 0 : 2,
                      color: isCurrentHymn
                          ? _colorController.primaryColor.value.withOpacity(0.2)
                          : _colorController.backgroundColor.value,
                      boxShape: NeumorphicBoxShape.roundRect(
                          BorderRadius.circular(8)),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isCurrentHymn
                                ? _colorController.primaryColor.value
                                : _colorController.primaryColor.value
                                    .withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: isCurrentHymn
                                ? Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : Text(
                                    '${hymn.hymnNumber}',
                                    style: TextStyle(
                                      color:
                                          _colorController.primaryColor.value,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hymn.title,
                                style: TextStyle(
                                  color: _colorController.textColor.value,
                                  fontWeight: isCurrentHymn
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Hymn ${hymn.hymnNumber}',
                                      style: TextStyle(
                                        color: _colorController.textColor.value
                                            .withOpacity(0.6),
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Show local audio status or download progress
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _hasLocalAudio(hymn)
                                          ? Colors.green.withOpacity(0.2)
                                          : _downloadProgress
                                                  .containsKey(hymn.id)
                                              ? Colors.orange.withOpacity(0.2)
                                              : _colorController
                                                  .primaryColor.value
                                                  .withOpacity(0.1),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _hasLocalAudio(hymn)
                                            ? Colors.green.withOpacity(0.5)
                                            : _downloadProgress
                                                    .containsKey(hymn.id)
                                                ? Colors.orange.withOpacity(0.5)
                                                : _colorController
                                                    .primaryColor.value
                                                    .withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: _hasLocalAudio(hymn)
                                          ? Icon(
                                              Icons.download_done,
                                              color: Colors.green,
                                              size: 20,
                                            )
                                          : _downloadProgress
                                                  .containsKey(hymn.id)
                                              ? Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    SizedBox(
                                                      width: 24,
                                                      height: 24,
                                                      child:
                                                          CircularProgressIndicator(
                                                        value:
                                                            _downloadProgress[
                                                                hymn.id],
                                                        strokeWidth: 2,
                                                        color: Colors.orange,
                                                        backgroundColor: Colors
                                                            .orange
                                                            .withOpacity(0.2),
                                                      ),
                                                    ),
                                                    Text(
                                                      '${(_downloadProgress[hymn.id]! * 100).toInt()}%',
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.orange,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : GestureDetector(
                                                  onTap: () =>
                                                      _downloadAudioForHymn(
                                                          hymn),
                                                  child: Icon(
                                                    Icons.download,
                                                    color: _colorController
                                                        .primaryColor.value,
                                                    size: 20,
                                                  ),
                                                ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isCurrentHymn)
                          Icon(
                            Icons.equalizer,
                            color: _colorController.primaryColor.value,
                            size: 16,
                          ),
                      ],
                    ),
                    onPressed: () {
                      if (!isCurrentHymn) {
                        _onHymnChange(hymn);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalAudioSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _audioService.getLocalAudioStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data!;
        final localCount = stats['totalFiles'] as int? ?? 0;
        final localSize = stats['totalSize'] as int? ?? 0;
        final localSizeMB = (localSize / (1024 * 1024)).toStringAsFixed(2);

        return Neumorphic(
          style: NeumorphicStyle(
              depth: 4,
              intensity: 0.8,
              color: _colorController.backgroundColor.value,
              boxShape:
                  NeumorphicBoxShape.roundRect(BorderRadius.circular(16))),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Local Audio Storage',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _colorController.textColor.value,
                      ),
                    ),
                    if (localCount > 0)
                      GestureDetector(
                        onTap: () async {
                          // Show confirmation dialog
                          final shouldClear = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Clear Local Audio'),
                              content: Text(
                                  'Are you sure you want to delete all locally downloaded audio files?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Clear'),
                                ),
                              ],
                            ),
                          );

                          if (shouldClear == true) {
                            await _audioService.clearAllLocalAudio();
                            await _initializePlaylist(); // Refresh playlist
                          }
                        },
                        child: Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Downloaded: $localCount hymns',
                  style: TextStyle(
                    fontSize: 14,
                    color: _colorController.textColor.value.withOpacity(0.8),
                  ),
                ),
                Text(
                  'Storage used: $localSizeMB MB',
                  style: TextStyle(
                    fontSize: 14,
                    color: _colorController.textColor.value.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the download icon (⬇) next to any hymn to download it for offline use.',
                  style: TextStyle(
                    fontSize: 12,
                    color: _colorController.textColor.value.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
            EnhancedAudioPlayerScreen(
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
          child: EnhancedAudioPlayerScreen(
            hymn: hymn,
            playlist: playlist,
            initialIndex: initialIndex,
          ),
        ),
      ),
    );
  }
}
