import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import '../../controller/color_controller.dart';
import '../../models/hymn.dart';
import '../../models/note.dart';
import 'package:fihirana/services/core/note_service.dart';
import 'edit_hymn_screen.dart';
import 'package:fihirana/services/features/hymn_service.dart';
import '../../l10n/app_localizations.dart';
import '../../controller/history_controller.dart';
import '../../controller/auth_controller.dart';
import '../../widgets/color_picker_widget.dart';
import 'package:fihirana/services/audio/audio_service.dart';
import '../../widgets/success_animation_dialog.dart';
import '../../widgets/hymn/hymn_search_popup_widget.dart';
import '../../widgets/player/compact_audio_player_widget.dart';
import '../../widgets/add_to_playlist_sheet.dart';
import '../../controller/recording_controller.dart';
import 'package:fihirana/services/core/translation_service.dart';
import '../../controller/language_controller.dart';

import '../../widgets/hymn/hymn_detail_widgets.dart';
import '../../widgets/hymn/hymn_improved_note_section_widget.dart';
import '../../widgets/hymn/hymn_action_widgets.dart';
import '../../widgets/hymn/hymn_detail_skeleton.dart';

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

    // Show recording overlay immediately with placeholder data
    // This ensures the FAB is visible during skeleton loading
    // Defer to post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordingController.showOverlay(widget.hymnId, 'Loading...');
    });

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
      child: HymnPageWidget(
        hymn: hymn,
        fontSize: _fontSize,
        countFontSize: _countFontSize,
        showHint: _show,
        isUserAuthenticated: isUserAuthenticated(),
        publicNotes: const [],
        userNote: _userNote,
        onNoteEdit: (note) => _showNoteEditor(note: note),
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
          title: HymnNumberWidget(
            hymnNumber: _hymn?.hymnNumber ?? '',
            fontSize: _fontSize,
            hymnId: _hymn?.id ?? widget.hymnId,
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
            AudioButtonWidget(
              hasAudio: _audioChecked && _hasAudio,
              isPlaying: _audioService.isHymnPlaying(_hymn?.id ?? ''),
              hymnId: _hymn?.id ?? '',
              onPressed: () => _showAudioPlayerDialog(),
            ),
            StreamBuilder<Map<String, String>>(
              stream: _hymnService.getFavoriteStatusStream(),
              builder: (context, snapshot) {
                final favoriteStatus = snapshot.data?[widget.hymnId] ?? '';
                final isFavorite = favoriteStatus.isNotEmpty;

                return FavoriteButtonWidget(
                  isFavorite: isFavorite,
                  favoriteStatus: favoriteStatus,
                  onPressed: () {
                    if (_hymn != null) {
                      _hymnService.toggleFavorite(_hymn!);
                    }
                  },
                );
              },
            ),
            StreamBuilder<Map<String, String>>(
              stream: _hymnService.getFavoriteStatusStream(),
              builder: (context, snapshot) {
                final favoriteStatus = snapshot.data?[widget.hymnId] ?? '';
                final isFavorite = favoriteStatus.isNotEmpty;

                return HymnPopupMenuWidget(
                  isFavorite: isFavorite,
                  canEditHymn: canEditHymn(),
                  isUserAuthenticated: isUserAuthenticated(),
                  hasUserNote: _userNote != null,
                  onToggleFavorite: () {
                    if (_hymn != null) {
                      _hymnService.toggleFavorite(_hymn!);
                    }
                  },
                  onEditHymn: () => _navigateToEditScreen(context),
                  onShowNoteEditor: () => _showNoteEditor(),
                  onShowFontSizeSlider: () {
                    setState(() {
                      _showSlider = !_showSlider;
                    });
                  },
                  onShowColorPicker: () =>
                      ColorPickerWidget.showColorPickerDialog(context),
                  onShowAudioPlayer: () => _showAudioPlayerDialog(),
                  onAddToPlaylist: () => _showAddToPlaylistDialog(),
                  onShowTranslation: _showTranslationDialog,
                );
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
                        child: HymnTitleWidget(
                          title: _hymn?.title ?? '',
                          hymnNumber: _hymn?.hymnNumber ?? '',
                          fontSize: _fontSize,
                          hymnId: _hymn?.id ?? widget.hymnId,
                        ),
                      ),
                      if (isFirebaseHymn() && _hymn != null)
                        StreamBuilder(
                          stream: FirebaseAuth.instance.authStateChanges(),
                          builder: (context, snapshot) {
                            final authController = Get.find<AuthController>();
                            final isAdmin = authController.isAdmin ||
                                authController.isSuperAdmin;

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
                                HymnBridgeWidget(
                                  bridge: _hymn!.bridge!,
                                  isExpanded: _show,
                                  fontSize: _fontSize,
                                  onToggle: () {
                                    setState(() {
                                      _show = !_show;
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (_showSlider)
                        FontSizeSliderWidget(
                          fontSize: _fontSize,
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
                      ? HymnDetailSkeleton(
                          fontSize: _fontSize,
                          countFontSize: _countFontSize,
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
    final authController = Get.find<AuthController>();
    final isAdmin = authController.isAdmin || authController.isSuperAdmin;
    final isCreator = _hymn!.createdByEmail == user?.email;

    return isAdmin || isCreator;
  }

  void _showNoteEditor({Note? note}) {
    if (!isUserAuthenticated()) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return NoteEditorWidget(
          note: note,
          userNoteContent: _userNote?.content,
          onSave: (content) async {
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
              final success =
                  await _noteService.saveNote(widget.hymnId, content);
              if (success) {
                await _loadUserNote();
              }
            }

            if (context.mounted) {
              if (content.isNotEmpty) {
                SuccessAnimationDialog.show(context,
                    message: AppLocalizations.of(context)!.noteSaved);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.noteDeleted),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          onDelete: note != null || _userNote != null
              ? () async {
                  if (note != null) {
                    await _noteService.deleteNote(note.id);
                  } else if (_userNote != null) {
                    await _noteService.deleteNote(_userNote!.id);
                    setState(() {
                      _userNote = null;
                    });
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text(AppLocalizations.of(context)!.noteDeleted),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              : null,
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

  Future<void> _showTranslationDialog() async {
    if (_hymn == null) return;

    final l10n = AppLocalizations.of(context)!;
    final languageController = Get.find<LanguageController>();

    // Determine target language
    // If current locale is MG, default to EN. Otherwise use current locale.
    String targetLang = languageController.currentLocale.value.languageCode;
    if (targetLang == 'mg') {
      targetLang = 'en';
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final translationService = TranslationService();

      // Check if model is downloaded
      final isDownloaded =
          await translationService.isModelDownloaded(targetLang);

      if (!isDownloaded) {
        // Ask user to download
        if (mounted) {
          Navigator.pop(context); // Close loading

          final shouldDownload = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.download),
              content: Text(
                  'Mila maka ny modelin\'ny teny $targetLang aloha. Te hanohy ve ianao?'), // "Need to download model first. Continue?"
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.download),
                ),
              ],
            ),
          );

          if (shouldDownload != true) return;

          // Show loading again
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) =>
                  const Center(child: CircularProgressIndicator()),
            );
          }

          final success = await translationService.downloadModel(targetLang);
          if (!success) {
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.downloadFailed)),
              );
            }
            return;
          }
        }
      }

      // Translate title
      final translatedTitle = await translationService.translate(
        text: _hymn!.title,
        sourceLanguage: 'mg', // Assuming hymns are in Malagasy
        targetLanguage: targetLang,
      );

      // Translate verses
      final List<String> translatedVerses = [];
      for (final verse in _hymn!.verses) {
        final translatedVerse = await translationService.translate(
          text: verse,
          sourceLanguage: 'mg',
          targetLanguage: targetLang,
        );
        translatedVerses.add(translatedVerse);
      }

      if (mounted) {
        Navigator.pop(context); // Close loading

        // Show translation result
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Get.find<ColorController>().backgroundColor.value,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.viewTranslation,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Get.find<ColorController>().textColor.value,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        Text(
                          translatedTitle,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color:
                                Get.find<ColorController>().primaryColor.value,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ...translatedVerses.asMap().entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${entry.key + 1}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Get.find<ColorController>()
                                        .primaryColor
                                        .value
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  entry.value,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Get.find<ColorController>()
                                        .textColor
                                        .value,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorOccurred)),
        );
      }
    }
  }
}
