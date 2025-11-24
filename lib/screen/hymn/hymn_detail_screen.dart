import 'dart:async';
import 'dart:io';
import 'package:fihirana/utility/screen_util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import '../../controller/color_controller.dart';
import '../../models/hymn.dart';
import '../../models/note.dart';
import '../../services/note_service.dart';
import 'edit_hymn_screen.dart';
import '../../services/hymn_service.dart';
import '../../l10n/app_localizations.dart';
import '../../controller/history_controller.dart';

import '../../widgets/color_picker_widget.dart';

import '../../services/audio_service.dart';
import '../../widgets/success_animation_dialog.dart';
import '../../widgets/compact_audio_player_widget.dart';
import '../../widgets/add_to_playlist_sheet.dart';
import '../recording/recording_manager_screen.dart';
import '../../controller/recording_controller.dart';

class HymnDetailScreen extends StatefulWidget {
  final String hymnId;

  const HymnDetailScreen({
    super.key,
    required this.hymnId,
  });

  @override
  State<HymnDetailScreen> createState() => _HymnDetailScreenState();
}

class _HymnDetailScreenState extends State<HymnDetailScreen>
    with TickerProviderStateMixin {
  final double _baseFontSize = 16.0;
  final double _baseCountFontSize = 50.0;
  double _fontSize = 16.0;
  double _countFontSize = 50.0;
  bool _show = true;
  bool _showSlider = false;
  bool _showNote = true;
  final HymnService _hymnService = HymnService();
  final NoteService _noteService = NoteService();
  final ColorController colorController = Get.find<ColorController>();
  final AudioService _audioService = AudioService.instance;
  late final HistoryController historyController;
  Hymn? _hymn;
  Note? _userNote;
  bool _hasAudio = false;
  bool _audioChecked = false;

  // Liquid swipe variables
  late LiquidController _liquidController;
  List<Hymn> _allHymns = [];
  List<Hymn> _adjacentHymns = []; // Will contain [previous, current, next]
  int _currentPageIndex = 1; // Start at middle page (current hymn)
  bool _isLoadingHymns = true;

  late AnimationController _heartAnimationController;
  late Animation<double> _heartScaleAnimation;
  late Animation<double> _heartOpacityAnimation;

  // Recording overlay state
  final RecordingController _recordingController =
      Get.put(RecordingController(), permanent: true);

  @override
  void initState() {
    super.initState();

    if (!Get.isRegistered<HistoryController>()) {
      Get.put(HistoryController());
    }
    historyController = Get.find<HistoryController>();

    _liquidController = LiquidController();
    _loadFontSize();
    _loadAllHymnsAndSetupSwipe();
    _loadUserNote();

    _hymnService.checkPendingSyncs();

    _heartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _heartScaleAnimation = Tween<double>(begin: 0.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _heartAnimationController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _heartOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _heartAnimationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _heartAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _heartAnimationController.reset();
      }
    });
  }

  @override
  void dispose() {
    _heartAnimationController.dispose();
    // Hide overlay when leaving screen, unless recording is in progress
    if (!_recordingController.isRecording.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _recordingController.hideOverlay();
      });
    }
    super.dispose();
  }

  void _handleDoubleTap() {
    if (_hymn != null) {
      _hymnService.toggleFavorite(_hymn!);
      _heartAnimationController.forward(from: 0.0);
    }
  }

  void _loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('fontSize') ?? _baseFontSize;
      _countFontSize = prefs.getDouble('countFontSize') ?? _baseCountFontSize;
    });
  }

  Future<void> _loadAllHymnsAndSetupSwipe() async {
    try {
      final allHymns = await _hymnService.getAllHymns();
      if (mounted) {
        setState(() {
          _allHymns = allHymns;
        });
        await _loadAdjacentHymns();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading all hymns: $e');
      }
      setState(() {
        _isLoadingHymns = false;
      });
    }
  }

  Future<void> _loadAdjacentHymns() async {
    // If all hymns list is empty, we still try to load the specific hymn
    // if (_allHymns.isEmpty) return;

    final currentIndex = _allHymns.indexWhere((h) => h.id == widget.hymnId);
    if (currentIndex == -1) {
      if (kDebugMode) {
        print(
            'Current hymn not found in all hymns list, trying to load individually');
      }

      // Try to load the hymn individually (e.g. from Firebase)
      final hymn = await _hymnService.getHymnById(widget.hymnId);

      if (mounted) {
        if (hymn != null) {
          setState(() {
            _hymn = hymn;
            _adjacentHymns = [hymn]; // Only this hymn available
            _currentPageIndex = 0;
            _isLoadingHymns = false;
          });

          // Add to history and check audio
          if (kDebugMode) {
            print(
                'Adding hymn to history: ${_hymn!.title} (${_hymn!.hymnNumber})');
          }
          await historyController.addToHistory(
            widget.hymnId,
            _hymn!.title,
            _hymn!.hymnNumber,
          );
          await _checkAudioAvailability();
          // Show persistent recording overlay
          _recordingController.showOverlay(_hymn!.id, _hymn!.title);
        } else {
          // Hymn really not found
          setState(() {
            _isLoadingHymns = false;
          });
          if (kDebugMode) {
            print('Hymn not found even individually');
          }
        }
      }
      return;
    }

    final List<Hymn> adjacent = [];

    // Add previous hymn if exists
    if (currentIndex > 0) {
      adjacent.add(_allHymns[currentIndex - 1]);
    }

    // Add current hymn
    adjacent.add(_allHymns[currentIndex]);

    // Add next hymn if exists
    if (currentIndex < _allHymns.length - 1) {
      adjacent.add(_allHymns[currentIndex + 1]);
    }

    if (mounted) {
      setState(() {
        _adjacentHymns = adjacent;
        _hymn = _allHymns[currentIndex];
        // Set page index based on whether previous hymn exists
        _currentPageIndex = currentIndex > 0 ? 1 : 0;
        _isLoadingHymns = false;
      });

      // Add to history and check audio
      if (_hymn != null) {
        if (kDebugMode) {
          print(
              'Adding hymn to history: ${_hymn!.title} (${_hymn!.hymnNumber})');
        }
        await historyController.addToHistory(
          widget.hymnId,
          _hymn!.title,
          _hymn!.hymnNumber,
        );
        await _checkAudioAvailability();
        // Show persistent recording overlay
        _recordingController.showOverlay(_hymn!.id, _hymn!.title);
      }
    }
  }

  void _onPageChangeCallback(int activePageIndex) async {
    if (_adjacentHymns.isEmpty || activePageIndex == _currentPageIndex) return;

    final currentHymnIndex = _allHymns.indexWhere((h) => h.id == _hymn!.id);
    if (currentHymnIndex == -1) return;

    int newHymnIndex;

    // Determine which direction we swiped
    if (activePageIndex > _currentPageIndex) {
      // Swiped to next hymn
      newHymnIndex = currentHymnIndex + 1;
    } else {
      // Swiped to previous hymn
      newHymnIndex = currentHymnIndex - 1;
    }

    // Validate index
    if (newHymnIndex < 0 || newHymnIndex >= _allHymns.length) return;

    final newHymn = _allHymns[newHymnIndex];

    // Update current hymn
    setState(() {
      _hymn = newHymn;
      _currentPageIndex = activePageIndex;
    });

    // Reload adjacent hymns for the new current hymn
    final List<Hymn> newAdjacent = [];

    if (newHymnIndex > 0) {
      newAdjacent.add(_allHymns[newHymnIndex - 1]);
    }
    newAdjacent.add(newHymn);
    if (newHymnIndex < _allHymns.length - 1) {
      newAdjacent.add(_allHymns[newHymnIndex + 1]);
    }

    setState(() {
      _adjacentHymns = newAdjacent;
      _currentPageIndex = newHymnIndex > 0 ? 1 : 0;
    });

    // Add to history and check audio for new hymn
    await historyController.addToHistory(
      newHymn.id,
      newHymn.title,
      newHymn.hymnNumber,
    );
    await _checkAudioAvailability();

    // Update persistent recording overlay
    _recordingController.showOverlay(newHymn.id, newHymn.title);

    // Reload user note for new hymn
    await _loadUserNote();
  }

  Future<void> _checkAudioAvailability() async {
    if (_hymn != null) {
      final audioService = AudioService.instance;
      final hasAudio = await audioService.checkAudioFileExists(_hymn!.id);
      if (mounted) {
        setState(() {
          _hasAudio = hasAudio;
          _audioChecked = true;
        });
      }
    }
  }

  Future<void> _loadUserNote() async {
    if (!isUserAuthenticated()) {
      return;
    }

    try {
      final note = await _noteService.getNote(widget.hymnId).timeout(
            const Duration(seconds: 5),
            onTimeout: () => null,
          );
      setState(() {
        _userNote = note;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user note: $e');
      }
    }
  }

  Widget _buildHymnPage(Hymn hymn, AppLocalizations l10n) {
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      child: Container(
        key: ValueKey(hymn.id),
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        color: colorController.backgroundColor.value,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_show &&
                  (hymn.hymnHint?.trim().toLowerCase().isNotEmpty ??
                      false)) ...[
                if (isUserAuthenticated())
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorController.primaryColor.value
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.createdBy}: ${hymn.createdBy}',
                          style: TextStyle(
                            fontSize: _fontSize * 0.8,
                            color: colorController.textColor.value,
                          ),
                        ),
                        if (hymn.createdByEmail != null)
                          Text(
                            l10n.emailLabel(hymn.createdByEmail!),
                            style: TextStyle(
                              fontSize: _fontSize * 0.8,
                              color: colorController.textColor.value,
                            ),
                          ),
                        Text(
                          '${l10n.date}: ${DateFormat('dd/MM/yyyy HH:mm').format(hymn.createdAt)}',
                          style: TextStyle(
                            fontSize: _fontSize * 0.8,
                            color: colorController.textColor.value,
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Text(
                    hymn.hymnHint ?? '',
                    style: TextStyle(
                      fontSize: 2 * _fontSize / 3,
                      color: colorController.textColor.value,
                    ),
                  ),
                ),
              ],
              if (isUserAuthenticated())
                FutureBuilder<bool>(
                  future: _checkInternetConnection(),
                  builder: (context, connectivitySnapshot) {
                    if (!connectivitySnapshot.hasData ||
                        !connectivitySnapshot.data!) {
                      return const SizedBox.shrink();
                    }

                    return StreamBuilder<List<Note>>(
                      stream: _noteService.getPublicNotesStream(hymn.id),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(child: Text(l10n.errorLoadingNotes));
                        }

                        if (!snapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final notes = snapshot.data!;

                        if (notes.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: notes.length,
                              itemBuilder: (context, index) {
                                final note = notes[index];
                                return FutureBuilder<bool>(
                                  future: _noteService.canEditNote(note),
                                  builder: (context, snapshot) {
                                    final canEdit = snapshot.data ?? false;

                                    return Container(
                                      margin: const EdgeInsets.only(top: 8),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: colorController
                                            .backgroundColor.value
                                            .withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                note.content,
                                                style: TextStyle(
                                                  fontSize: _fontSize * 0.9,
                                                  color: colorController
                                                      .textColor.value,
                                                ),
                                              ),
                                              if (canEdit)
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.edit,
                                                    size: _fontSize,
                                                    color: colorController
                                                        .iconColor.value,
                                                  ),
                                                  onPressed: () =>
                                                      _showNoteEditor(
                                                          note: note),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              for (int i = 0; i < hymn.verses.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 30.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.25,
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: _countFontSize,
                                fontWeight: FontWeight.bold,
                                color: colorController.primaryColor.value,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 30.0),
                        child: Text(
                          '${i + 1}. ${hymn.verses[i]}',
                          style: TextStyle(
                            fontSize: _fontSize,
                            color: colorController.textColor.value,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(
                height: getScreenHeight(context) / 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GetBuilder<ColorController>(
      builder: (colorController) => Scaffold(
        backgroundColor: colorController.backgroundColor.value,
        appBar: AppBar(
          leading: IconButton(
              onPressed: () {
                Get.back();
              },
              icon: Icon(
                Icons.arrow_back_ios_outlined,
                color: colorController.iconColor.value,
              )),
          backgroundColor: colorController.backgroundColor.value,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: GestureDetector(
            child: Hero(
              tag: 'hymn_number_${_hymn?.id ?? widget.hymnId}',
              child: Material(
                color: Colors.transparent,
                child: Text(
                  _hymn?.hymnNumber ?? '',
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: colorController.iconColor.value,
                    fontWeight: FontWeight.bold,
                    fontSize: _fontSize,
                  ),
                ),
              ),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return HymnSearchPopup(
                    colorController: colorController,
                    onHymnSelected: (selectedHymn) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              HymnDetailScreen(hymnId: selectedHymn.id),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          actions: [
            if (_audioChecked && _hasAudio)
              Obx(() => IconButton(
                    icon: Stack(
                      children: [
                        Icon(
                          Icons.music_note,
                          color: _audioService.isHymnPlaying(_hymn?.id ?? '')
                              ? Theme.of(context).colorScheme.primary
                              : colorController.iconColor.value,
                        ),
                        if (_audioService.isHymnPlaying(_hymn?.id ?? ''))
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: () {
                      _showAudioPlayerDialog();
                    },
                  )),
            StreamBuilder<Map<String, String>>(
              stream: _hymnService.getFavoriteStatusStream(),
              builder: (context, snapshot) {
                final favoriteStatus = snapshot.data?[widget.hymnId] ?? '';
                final isFavorite = favoriteStatus.isNotEmpty;

                return IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite
                        ? (favoriteStatus == 'cloud' ? Colors.red : Colors.blue)
                        : colorController.iconColor.value,
                  ),
                  onPressed: () {
                    if (_hymn != null) {
                      _hymnService.toggleFavorite(_hymn!);
                    }
                  },
                );
              },
            ),
            PopupMenuButton<String>(
              color: colorController.primaryColor.value,
              icon: Icon(
                Icons.menu_sharp,
                color: colorController.iconColor.value,
              ),
              onSelected: (String item) {
                switch (item) {
                  case 'edit':
                    _navigateToEditScreen(
                      context,
                    );
                    break;
                  case 'switch_value':
                    setState(() {
                      _show = !_show;
                    });
                    break;
                  case 'font_size':
                    setState(() {
                      _showSlider = !_showSlider;
                    });
                    break;
                  case 'add_note':
                    _showNoteEditor();
                    break;
                  case 'toggle_note':
                    setState(() {
                      _showNote = !_showNote;
                    });
                    break;
                  case 'color_picker':
                    ColorPickerWidget.showColorPickerDialog(context);
                    break;
                  case 'audio_player':
                    _showAudioPlayerDialog();
                    break;
                  case 'add_to_playlist':
                    _showAddToPlaylistDialog();
                    break;
                  case 'my_recordings':
                    Get.to(() => const RecordingManagerScreen());
                    break;
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  if (canEditHymn())
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit,
                            color: colorController.textColor.value,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.edit,
                          ),
                        ],
                      ),
                    ),
                  if (isUserAuthenticated())
                    PopupMenuItem<String>(
                      value: 'add_note',
                      child: Row(
                        children: [
                          Icon(
                            _userNote != null
                                ? Icons.edit_note
                                : Icons.note_add,
                            color: colorController.textColor.value,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _userNote != null ? l10n.editNote : l10n.add,
                          ),
                        ],
                      ),
                    ),
                  PopupMenuItem<String>(
                    value: 'font_size',
                    child: Row(
                      children: [
                        Icon(
                          Icons.text_fields,
                          color: colorController.textColor.value,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.font,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'color_picker',
                    child: Row(
                      children: [
                        Icon(
                          Icons.color_lens,
                          color: colorController.textColor.value,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.color,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'add_to_playlist',
                    child: Row(
                      children: [
                        Icon(
                          Icons.playlist_add,
                          color: colorController.textColor.value,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.addToPlaylist,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'my_recordings',
                    child: Row(
                      children: [
                        Icon(
                          Icons.mic,
                          color: colorController.textColor.value,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'My Recordings',
                        ),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Center(
                        child: Hero(
                          tag: 'hymn_title_${_hymn?.id ?? widget.hymnId}',
                          child: Material(
                            color: Colors.transparent,
                            child: Text(
                              _hymn?.title ?? '',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: _fontSize * 1.2,
                                fontWeight: FontWeight.bold,
                                color: colorController.textColor.value,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (isFirebaseHymn() && _hymn != null)
                        StreamBuilder(
                          stream: FirebaseAuth.instance.authStateChanges(),
                          builder: (context, snapshot) {
                            final user = FirebaseAuth.instance.currentUser;
                            final isAdmin = user?.email ==
                                'manassehrandriamitsiry@gmail.com';

                            if (isAdmin) {
                              return Text(
                                '${l10n.createdBy}: ${_hymn?.createdBy}',
                                style: TextStyle(
                                  fontSize: _fontSize * 0.8,
                                  color: colorController.textColor.value,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      const SizedBox(height: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        child: Card(
                          color: colorController.backgroundColor.value,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_hymn?.bridge != null &&
                                  (_hymn?.bridge
                                          ?.trim()
                                          .toLowerCase()
                                          .isNotEmpty ??
                                      false))
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _show = !_show;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              l10n.everyVerseChorus,
                                              style: TextStyle(
                                                fontSize: _fontSize + 2,
                                                fontWeight: FontWeight.bold,
                                                color: colorController
                                                    .textColor.value,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              _show
                                                  ? Icons.expand_less
                                                  : Icons.expand_more,
                                              color: colorController
                                                  .iconColor.value,
                                            ),
                                          ],
                                        ),
                                        if (_show)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              _hymn?.bridge ?? '',
                                              style: TextStyle(
                                                fontSize: _fontSize,
                                                color: colorController
                                                    .textColor.value,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (_showSlider)
                        Slider(
                          value: _fontSize,
                          min: 12,
                          max: 40,
                          divisions: 28,
                          label: _fontSize.round().toString(),
                          onChanged: (double value) {
                            setState(() {
                              _fontSize = value;
                              _countFontSize =
                                  value * (_baseCountFontSize / _baseFontSize);
                            });
                          },
                          onChangeEnd: (double value) async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setDouble('fontSize', value);
                            if (mounted) {
                              setState(() {
                                _showSlider = false;
                              });
                            }
                          },
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoadingHymns
                      ? Center(
                          child: CircularProgressIndicator(
                            color: colorController.primaryColor.value,
                          ),
                        )
                      : _adjacentHymns.isEmpty
                          ? Center(
                              child: Text(
                                l10n.noHymnsAvailable,
                                style: TextStyle(
                                  color: colorController.textColor.value,
                                ),
                              ),
                            )
                          : Stack(
                              alignment: Alignment.center,
                              children: [
                                LiquidSwipe(
                                  key: ValueKey(_hymn?.id),
                                  pages: _adjacentHymns
                                      .map((hymn) => _buildHymnPage(hymn, l10n))
                                      .toList(),
                                  initialPage: _currentPageIndex,
                                  liquidController: _liquidController,
                                  onPageChangeCallback: _onPageChangeCallback,
                                  waveType: WaveType.liquidReveal,
                                  enableLoop: false,
                                  enableSideReveal: false,
                                  ignoreUserGestureWhileAnimating: true,
                                  disableUserGesture: false,
                                ),
                                IgnorePointer(
                                  child: AnimatedBuilder(
                                    animation: _heartAnimationController,
                                    builder: (context, child) {
                                      return Opacity(
                                        opacity: _heartOpacityAnimation.value,
                                        child: Transform.scale(
                                          scale: _heartScaleAnimation.value,
                                          child: Icon(
                                            Icons.favorite,
                                            color: Colors.red
                                                .withValues(alpha: 0.8),
                                            size: 100,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: null,
      ),
    );
  }

  bool isUserAuthenticated() {
    return FirebaseAuth.instance.currentUser != null;
  }

  bool isFirebaseHymn() {
    if (_hymn == null) return false;

    return _hymn!.createdByEmail != null && _hymn!.createdBy != 'Local File';
  }

  bool canEditHymn() {
    if (!isUserAuthenticated() || !isFirebaseHymn() || _hymn == null) {
      return false;
    }

    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = user?.email == 'manassehrandriamitsiry@gmail.com';
    final isCreator = _hymn!.createdByEmail == user?.email;

    return isAdmin || isCreator;
  }

  void _showNoteEditor({Note? note}) {
    if (!isUserAuthenticated()) return;

    final noteController =
        TextEditingController(text: note?.content ?? _userNote?.content ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              color: colorController.backgroundColor.value,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        note != null ? l10n.editNote : l10n.myPersonalNote,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorController.textColor.value,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: colorController.iconColor.value,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noteInstructions,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorController.textColor.value
                          .withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: l10n.enterYourNote,
                      hintStyle: TextStyle(
                        color: colorController.textColor.value
                            .withValues(alpha: 0.5),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: colorController.textColor.value
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: colorController.textColor.value
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: colorController.primaryColor.value,
                        ),
                      ),
                    ),
                    style: TextStyle(
                      color: colorController.textColor.value,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (note != null || _userNote != null)
                        TextButton(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor:
                                    colorController.backgroundColor.value,
                                title: Text(
                                  l10n.deleteNoteConfirm,
                                  style: TextStyle(
                                      color: colorController.textColor.value),
                                ),
                                content: Text(
                                  l10n.deleteNoteMessage,
                                  style: TextStyle(
                                      color: colorController.textColor.value),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text(
                                      l10n.no,
                                      style: TextStyle(
                                          color:
                                              colorController.textColor.value),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text(
                                      l10n.yes,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true) {
                              if (note != null) {
                                await _noteService.deleteNote(note.id);
                              } else {
                                await _noteService.deleteNote(_userNote!.id);
                                setState(() {
                                  _userNote = null;
                                });
                              }

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.noteDeleted),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            }
                          },
                          child: Text(
                            l10n.delete,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          l10n.cancel,
                          style:
                              TextStyle(color: colorController.textColor.value),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final content = noteController.text.trim();
                          if (content.isEmpty) {
                            if (note != null) {
                              await _noteService.deleteNote(note.id);
                            } else if (_userNote != null) {
                              await _noteService.deleteNote(_userNote!.id);
                              setState(() {
                                _userNote = null;
                              });
                            }
                          } else {
                            final success = await _noteService.saveNote(
                                widget.hymnId, content);
                            if (success) {
                              if (note == null) {
                                await _loadUserNote();
                              }
                            }
                          }

                          if (context.mounted) {
                            Navigator.pop(context);

                            if (content.isNotEmpty) {
                              SuccessAnimationDialog.show(context,
                                  message: l10n.noteSaved);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.noteDeleted),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorController.primaryColor.value,
                          foregroundColor:
                              colorController.backgroundColor.value,
                        ),
                        child: Text(l10n.save),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAudioPlayerDialog() {
    if (_hymn == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StreamBuilder<Map<String, String>>(
        stream: _hymnService.getFavoriteStatusStream(),
        builder: (context, snapshot) {
          return CompactAudioPlayerWidget(
            hymn: _hymn!,
            playlist: _allHymns,
            onToggleFavorite: () {
              if (_hymn != null) {
                _hymnService.toggleFavorite(_hymn!);
              }
            },
            onHymnChange: (hymn) {
              // Find the index of the new hymn
              final index = _allHymns.indexWhere((h) => h.id == hymn.id);
              if (index != -1) {
                // Update the page controller to show the new hymn
                _liquidController.jumpToPage(page: index > 0 ? 1 : 0);
                _onPageChangeCallback(index > 0 ? 1 : 0);
              }
            },
          );
        },
      ),
    );
  }

  void _navigateToEditScreen(BuildContext context) {
    if (_hymn == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditHymnScreen(hymn: _hymn!),
      ),
    );
  }

  void _showAddToPlaylistDialog() {
    if (_hymn == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddToPlaylistSheet(
        hymnId: _hymn!.id,
        onHymnAdded: () {
          // Optional: Show success feedback if needed, though the controller handles snackbars
        },
      ),
    );
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } on SocketException catch (_) {
      return false;
    }
    return false;
  }
}

class HymnSearchPopup extends StatefulWidget {
  final ColorController colorController;
  final Function(Hymn) onHymnSelected;

  const HymnSearchPopup({
    super.key,
    required this.colorController,
    required this.onHymnSelected,
  });

  @override
  State<HymnSearchPopup> createState() => _HymnSearchPopupState();
}

class _HymnSearchPopupState extends State<HymnSearchPopup> {
  final HymnService _hymnService = HymnService();
  List<Hymn> _hymns = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHymns();
  }

  Future<void> _loadHymns() async {
    try {
      final hymns = await _hymnService.searchHymns('');
      setState(() {
        _hymns = hymns;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _searchHymns(String query) {
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () async {
      try {
        final hymns = await _hymnService.searchHymns(query);
        setState(() {
          _hymns = hymns;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: widget.colorController.backgroundColor.value,
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchHymns,
                hintStyle: TextStyle(
                  color: widget.colorController.textColor.value
                      .withValues(alpha: 0.7),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: widget.colorController.textColor.value,
                ),
              ),
              style: TextStyle(
                color: widget.colorController.textColor.value,
              ),
              onChanged: _searchHymns,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _hymns.isEmpty
                      ? Center(
                          child: Text(
                            l10n.noHymnsFound,
                            style: TextStyle(
                              color: widget.colorController.textColor.value,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _hymns.length,
                          itemBuilder: (context, index) {
                            final hymn = _hymns[index];
                            return ListTile(
                              title: Text(
                                '${hymn.hymnNumber} - ${hymn.title}',
                                style: TextStyle(
                                  color: widget.colorController.textColor.value,
                                ),
                              ),
                              onTap: () {
                                widget.onHymnSelected(hymn);
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
