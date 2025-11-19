import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:get/get.dart';
import '../../controller/color_controller.dart';
import '../../models/hymn.dart';
import '../../services/hymn_service.dart';
import '../../services/audio_service.dart';
import '../../services/audio_file_mapping.dart';
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
  late Hymn _currentHymn;
  List<Hymn> _playlist = [];
  int _currentIndex = 0;
  bool _autoPlayNext = false;
  bool _isLoadingPlaylist = true;

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

    // Create playlist of hymns that have audio
    print('EnhancedAudioPlayer: Creating playlist of hymns with audio');
    
    final audioMapping = AudioFileMapping();
    
    // Ensure mapping is up to date
    if (audioMapping.isCacheExpired()) {
      print('EnhancedAudioPlayer: Audio mapping expired, updating...');
      await audioMapping.updateAudioFileMapping();
    }
    
    final audioFiles = audioMapping.getAllAudioFiles();
    final audioCount = audioFiles.length;
    print('EnhancedAudioPlayer: Found $audioCount hymns with audio');
    
    // Debug: Print sample audio files
    print('EnhancedAudioPlayer: Sample audio files: ${audioFiles.entries.take(5).toList()}');
    print('EnhancedAudioPlayer: Current hymn ID: ${widget.hymn.id}');
    print('EnhancedAudioPlayer: Current hymn in audio files: ${audioFiles.containsKey(widget.hymn.id)}');

    // Create playlist by matching hymns with available audio files
    final filteredList = <Hymn>[];
    
    for (final hymn in initialList) {
      if (audioFiles.containsKey(hymn.id)) {
        filteredList.add(hymn);
        print('EnhancedAudioPlayer: Added hymn ${hymn.id} to playlist');
      }
    }
    
    // Always include current hymn even if not in audio files (to avoid empty screen)
    if (!filteredList.any((h) => h.id == widget.hymn.id)) {
      filteredList.insert(0, widget.hymn);
      print('EnhancedAudioPlayer: Added current hymn ${widget.hymn.id} at beginning of playlist');
    }
    
    print('EnhancedAudioPlayer: Final playlist has ${filteredList.length} hymns');

    print('EnhancedAudioPlayer: Filtered playlist has ${filteredList.length} hymns');

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
                  _buildPlaylistSection(),
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
                              Text(
                                'Hymn ${hymn.hymnNumber}',
                                style: TextStyle(
                                  color: _colorController.textColor.value
                                      .withOpacity(0.6),
                                  fontSize: 12,
                                ),
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
