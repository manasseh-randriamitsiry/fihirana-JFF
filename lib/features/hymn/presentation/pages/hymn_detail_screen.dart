import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/bible/data/services/note_service.dart';
import 'edit_hymn_screen.dart';
import 'package:fihirana/features/hymn/data/services/hymn_service.dart';
import 'package:fihirana/features/history/di/history_di.dart';
import 'package:fihirana/features/audio/data/services/audio_service.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/bible/domain/entities/note.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/features/history/presentation/controllers/history_controller.dart';
import 'package:fihirana/features/auth/presentation/controllers/auth_controller.dart';
import 'package:fihirana/features/recording/presentation/controllers/recording_controller.dart';
import 'package:fihirana/features/recording/presentation/widgets/recording_overlay_manager.dart';
import 'package:fihirana/shared/widgets/common/color_picker_widget.dart';
import 'package:fihirana/shared/widgets/animations/success_animation_dialog.dart';
import 'package:fihirana/features/hymn/presentation/widgets/hymn_detail_widgets.dart';
import 'package:fihirana/features/hymn/presentation/widgets/hymn_improved_note_section_widget.dart';
import 'package:fihirana/features/hymn/presentation/widgets/hymn_action_widgets.dart';
import 'package:fihirana/features/hymn/presentation/widgets/hymn_detail_skeleton.dart';
import 'package:fihirana/features/audio/presentation/widgets/compact_audio_player_widget.dart';
import 'package:fihirana/features/playlist/presentation/widgets/add_to_playlist_sheet.dart';
import 'package:fihirana/features/hymn/presentation/widgets/hymn_search_popup_widget.dart';

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
  final bool _show = true;
  bool _showSlider = false;

  final HymnService _hymnService = HymnService();
  final NoteService _noteService = NoteService();
  final AudioService _audioService = AudioService.instance;
  late final HistoryController historyController;
  Hymn? _hymn;
  Note? _userNote;
  bool _hasAudio = false;
  bool _audioChecked = false;

  late final PageController _pageController;
  List<Hymn> _allHymns = [];
  int _currentPageIndex = 0;
  bool _isLoadingHymns = true;

  late AnimationController _heartAnimationController;
  late Animation<double> _heartScaleAnimation;
  late Animation<double> _heartOpacityAnimation;

  // Recording overlay state
  late final RecordingController _recordingController;

  @override
  void initState() {
    super.initState();

    // Initialize recording controller
    _recordingController = Get.find<RecordingController>();

    // Initialize history controller (ensure HistoryDI is initialized)
    try {
      historyController = HistoryDI.historyController;
    } catch (e) {
      // HistoryDI not initialized yet, initialize it
      HistoryDI.initialize();
      historyController = HistoryDI.historyController;
    }

    _pageController = PageController();
    _loadFontSize();
    _loadAllHymnsAndSetupSwipe();
    _loadUserNote();
    // Defer sync work until after the first frame so opening the detail page
    // stays responsive on slower devices.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hymnService.checkPendingSyncs();
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
    _pageController.dispose();
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
      if (kDebugMode) {
        print('Loaded ${allHymns.length} hymns from service');
      }
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
    if (kDebugMode) {
      print('Loading adjacent hymns. All hymns count: ${_allHymns.length}');
    }

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
            _allHymns = [hymn];
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

    if (mounted) {
      setState(() {
        _hymn = _allHymns[currentIndex];
        _currentPageIndex = currentIndex;
        _isLoadingHymns = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(currentIndex);
        }
      });

      // Add to history and check audio
      if (_hymn != null) {
        if (kDebugMode) {
          print(
              'Adding hymn to history: ${_hymn!.title} (${_hymn!.hymnNumber})');
          final authController = Get.find<AuthController>();
          print('User authenticated: ${authController.isAuthenticated}');
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

  void _onPageChangeCallback(int newHymnIndex) async {
    if (newHymnIndex == _currentPageIndex || newHymnIndex >= _allHymns.length) {
      return;
    }
    final newHymn = _allHymns[newHymnIndex];
    setState(() {
      _hymn = newHymn;
      _currentPageIndex = newHymnIndex;
      _audioChecked = false;
      _hasAudio = false;
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
      if (kDebugMode) {
        print(
            'HymnDetailScreen: Checking audio for hymn ${_hymn!.id} (${_hymn!.title})');
      }
      final audioService = AudioService.instance;
      final hasAudio = await audioService.checkAudioFileExists(_hymn!.id);
      if (mounted) {
        if (kDebugMode) {
          print(
              'HymnDetailScreen: Audio check result for ${_hymn!.id}: $hasAudio');
        }
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
      final hymnId = _hymn?.id ?? widget.hymnId;
      final note = await _noteService.getNote(hymnId).timeout(
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
        isUserAuthenticated: FirebaseAuth.instance.currentUser != null,
        publicNotes: const [],
        userNote: _userNote,
        onNoteEdit: (note) => _showNoteEditor(note: note),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => HymnSearchPopup(
        onHymnSelected: (hymn) {
          Navigator.pop(context); // Close dialog
          _navigateToHymn(hymn);
        },
      ),
    );
  }

  void _navigateToHymn(Hymn hymn) {
    if (hymn.id == _hymn?.id) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HymnDetailScreen(
          hymnId: hymn.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final authController = Get.find<AuthController>();
    final currentUser = FirebaseAuth.instance.currentUser;
    final isAuthenticated = currentUser != null;
    final canEditCurrentHymn = _hymn != null &&
        isAuthenticated &&
        _hymn!.createdByEmail != null &&
        _hymn!.createdBy != 'Local File' &&
        (authController.isAdmin ||
            authController.isSuperAdmin ||
            _hymn!.createdByEmail == currentUser.email);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Get.back();
            },
            icon: Icon(
              Icons.arrow_back_ios_outlined,
              color: colorScheme.onSurface,
            )),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            _showSearchDialog();
          },
          child: Text(
            _hymn?.hymnNumber ?? '',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          AudioButtonWidget(
            hasAudio: _audioChecked && _hasAudio,
            isPlaying: _audioService.isHymnPlaying(_hymn?.id ?? ''),
            hymnId: _hymn?.id ?? '',
            onPressed: () => _showAudioPlayerDialog(),
          ),
          StreamBuilder<Map<String, String>>(
            initialData: _hymnService.currentFavoriteStatus,
            stream: _hymnService.getFavoriteStatusStream(),
            builder: (context, snapshot) {
              final favoriteStatus =
                  snapshot.data?[_hymn?.id ?? widget.hymnId] ?? '';
              final isFavorite = favoriteStatus.isNotEmpty;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FavoriteButtonWidget(
                    isFavorite: isFavorite,
                    favoriteStatus: favoriteStatus,
                    onPressed: () {
                      if (_hymn != null) {
                        _hymnService.toggleFavorite(_hymn!);
                      }
                    },
                  ),
                  HymnPopupMenuWidget(
                    isFavorite: isFavorite,
                    canEditHymn: canEditCurrentHymn,
                    isUserAuthenticated: isAuthenticated,
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
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // PageView lazily builds only the visible hymn and its neighbours.
          _isLoadingHymns
              ? HymnDetailSkeleton(
                  fontSize: _fontSize,
                  countFontSize: _countFontSize,
                )
              : _allHymns.isEmpty
                  ? Center(
                      child: Text(
                        l10n.noHymnsAvailable,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    )
                  : PageView.builder(
                      controller: _pageController,
                      itemCount: _allHymns.length,
                      onPageChanged: _onPageChangeCallback,
                      itemBuilder: (context, index) =>
                          _buildHymnPage(_allHymns[index], l10n),
                    ),

          // Heart Animation Overlay
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
                      color: colorScheme.error.withValues(alpha: 0.8),
                      size: 100,
                    ),
                  ),
                );
              },
            ),
          ),

          // Font Size Slider Overlay
          if (_showSlider)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Card(
                elevation: 0,
                color: colorScheme.surface,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                        color:
                            colorScheme.outlineVariant.withValues(alpha: .65),
                        width: 1)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FontSizeSliderWidget(
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
                ),
              ),
            ),

          // Recording controls are intentionally scoped to the hymn reader.
          // Keeping this out of the global shell prevents it from covering
          // unrelated routes such as the Bible reader.
          const Positioned.fill(
            child: RecordingOverlayManager(),
          ),
        ],
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
                    message: AppLocalizations.of(context).noteSaved);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context).noteDeleted),
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
                        content: Text(AppLocalizations.of(context).noteDeleted),
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
      builder: (context) => CompactAudioPlayerWidget(
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
            _pageController.jumpToPage(index);
          }
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
}
