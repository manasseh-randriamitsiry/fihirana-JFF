import 'package:flutter/foundation.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../controller/color_controller.dart';
import '../../controller/hymn_controller.dart';
import '../../widgets/hymn_list_item.dart';
import '../../widgets/hymn_search_field.dart';
import '../../widgets/language_picker_widget.dart';
import '../../widgets/skeleton_hymn_list.dart';
import '../../widgets/empty_state_widget.dart';
import '../player/audio_player_screen.dart';
import '../../utility/navigation_utility.dart';
import '../../services/version_check_service.dart';
import '../../services/audio_service.dart';
import '../../services/hymn_service.dart';
import '../../models/hymn.dart';
import '../../l10n/app_localizations.dart';

class AccueilScreen extends StatefulWidget {
  final Function() openDrawer;
  final bool showMenuButton;

  const AccueilScreen({
    super.key,
    required this.openDrawer,
    this.showMenuButton = true,
  });

  @override
  AccueilScreenState createState() => AccueilScreenState();
}

class AccueilScreenState extends State<AccueilScreen> {
  late final HymnController _hymnController;
  bool _updateAvailable = false;
  bool _isDownloading = false;
  final Set<String> _checkedHymnIds = <String>{};

  @override
  void initState() {
    super.initState();
    // Initialize the controller properly to avoid disposal issues
    _hymnController = Get.put<HymnController>(HymnController(), permanent: true);

    VersionCheckService.setOnUpdateAvailableCallback(() {
      if (mounted) {
        setState(() {
          _updateAvailable = true;
        });
      }
    });
  }

  void _showAudioPlayerDialog(Hymn hymn) {
    // Navigate to enhanced player - it will load all hymns as playlist
    AudioPlayerNavigator.navigateToEnhancedPlayer(
      context,
      hymn: hymn,
      playlist: null, // Let the enhanced player handle loading all hymns
      initialIndex: null,
    );
  }

  void _showCurrentPlayingDialog() async {
    final audioService = AudioService.instance;
    final currentHymnId = audioService.currentPlayingHymnId;

    if (currentHymnId.isEmpty) return;

    // Get hymn data
    final hymnService = HymnService();
    final hymn = await hymnService.getHymnById(currentHymnId);

    if (hymn != null && context.mounted) {
      _showAudioPlayerDialog(hymn);
    }
  }

  Future<void> _showAudioPlayerWithFirstHymn() async {
    // Get the first hymn from the current filtered list
    final hymns =
    _hymnController.filterHymnList(await _hymnController.hymnsStream.first);

    if (hymns.isNotEmpty && context.mounted) {
      _showAudioPlayerDialog(hymns.first);
    }
  }

  void _batchCheckAudioFiles(List<Hymn> hymns) {
    final audioService = AudioService.instance;
    final List<String> uncheckedIds = [];

    for (final hymn in hymns) {
      if (!_checkedHymnIds.contains(hymn.id)) {
        uncheckedIds.add(hymn.id);
      }
    }

    if (uncheckedIds.isNotEmpty) {
      // Use new cache service for efficient batch checking
      audioService.checkAudioFilesExist(uncheckedIds).then((results) {
        _checkedHymnIds.addAll(results.keys);
        if (kDebugMode) {
          print(
              'AccueilScreen: Batch checked ${uncheckedIds.length} hymns, ${results.values.where((v) => v).length} have audio');
        }
      }).catchError((error) {
        // Silently handle errors to not affect UI
        if (kDebugMode) {
          print('Batch audio check error: $error');
        }
      });
    }
  }

  void _preloadCommonHymns(List<Hymn> hymns) {
    // Preload first 20 hymns to improve user experience
    final commonHymnIds = hymns.take(20).map((h) => h.id).toList();
    AudioService.instance.preloadCommonHymns(commonHymnIds);
  }





  Future<void> _downloadAndInstallUpdate() async {
    try {
      setState(() {
        _isDownloading = true;
      });

      await VersionCheckService.downloadAndInstallLatestVersion();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });

        if (context.mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.errorDownloadingUpdate}: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ColorController>(
      builder: (colorController) => Obx(() {
        final textColor = colorController.textColor.value;
        final backgroundColor = colorController.backgroundColor.value;
        final iconColor = colorController.iconColor.value;
        final defaultTextStyle = TextStyle(color: textColor, inherit: true);

        return NeumorphicTheme(
          themeMode: colorController.themeMode,
          theme: colorController.getNeumorphicLightTheme(),
          darkTheme: colorController.getNeumorphicDarkTheme(),
          child: Scaffold(
            backgroundColor: backgroundColor,
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: backgroundColor,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  floating: true,
                  pinned: true,
                  snap: true,
                  leading: widget.showMenuButton
                      ? IconButton(
                    key: const ValueKey('menu_button'),
                    icon: Icon(Icons.menu, color: iconColor),
                    onPressed: widget.openDrawer,
                  )
                      : null,
                  title: Text(
                    AppLocalizations.of(context)!.appTitleShort,
                    style: defaultTextStyle.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                    ),
                  ),
                  actions: [
                    if (_updateAvailable)
                      IconButton(
                        key: const ValueKey('update_button'),
                        icon: _isDownloading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.orange),
                          ),
                        )
                            : const Icon(Icons.system_update,
                            color: Colors.orange),
                        onPressed: _isDownloading ? null : _downloadAndInstallUpdate,
                      ),
                    Obx(() {
                      final audioService = AudioService.instance;
                      final currentHymnId = audioService.currentPlayingHymnId;
                      final isPlaying =
                          currentHymnId.isNotEmpty && audioService.isPlaying;

                      return IconButton(
                        key: const ValueKey('now_playing_button'),
                        icon: Stack(
                          children: [
                            Icon(
                              Icons.play_circle,
                              color: isPlaying
                                  ? Theme.of(context).colorScheme.primary
                                  : iconColor,
                            ),
                            if (isPlaying)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: backgroundColor,
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onPressed: () async {
                          if (isPlaying) {
                            _showCurrentPlayingDialog();
                          } else {
                            await _showAudioPlayerWithFirstHymn();
                          }
                        },
                      );
                    }),
                    IconButton(
                      key: const ValueKey('language_button'),
                      icon: Icon(Icons.language, color: iconColor),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const LanguagePickerDialog(),
                        );
                      },
                    ),
                    IconButton(
                      key: const ValueKey('favorites_button'),
                      icon: Icon(Icons.favorite, color: iconColor),
                      onPressed: () => NavigationUtility.navigateToFavorites(),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: HymnSearchField(
                    controller: _hymnController.safeSearchController,
                    defaultTextStyle: defaultTextStyle,
                    textColor: textColor,
                    iconColor: iconColor,
                    backgroundColor: backgroundColor,
                    onChanged: () {
                      // Check if controller is still valid before updating state
                      if (mounted && !_hymnController.isDisposed) {
                        setState(() {});
                      }
                    },
                  ),
                ),
                StreamBuilder<List<Hymn>>(
                  stream: _hymnController.hymnsStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context)!
                                .errorOccurredWithDetails(
                                snapshot.error.toString()),
                            style: defaultTextStyle,
                          ),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SkeletonHymnList();
                    }

                    final hymns =
                    _hymnController.filterHymnList(snapshot.data ?? []);
                    if (hymns.isEmpty) {
                      return SliverFillRemaining(
                        child: EmptyStateWidget(
                          message: AppLocalizations.of(context)!.noHymnsFound,
                          icon: Icons.music_off_rounded,
                          actionLabel:
                          AppLocalizations.of(context)!.clearSearch,
                          onActionPressed: () {
                            if (!_hymnController.isDisposed) {
                              _hymnController.safeSearchController.clear();
                              // Trigger rebuild/search update if needed, though controller listener should handle it
                              setState(() {});
                            }
                          },
                        ),
                      );
                    }

                    // Initial batch check for first 10 items and preload common hymns
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final List<Hymn> firstTen =
                      hymns.length >= 10 ? hymns.sublist(0, 10) : hymns;
                      _batchCheckAudioFiles(firstTen);

                      // Preload common hymns in background
                      _preloadCommonHymns(hymns);
                    });

                    return StreamBuilder<Map<String, String>>(
                      stream: _hymnController.getFavoriteStatusStream(),
                      builder: (context, favoriteSnapshot) {
                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                                (context, index) {
                              final hymn = hymns[index];
                              return HymnListItem(
                                key: ValueKey(hymn.id),
                                hymn: hymn,
                                textColor: textColor,
                                backgroundColor: backgroundColor,
                                onFavoritePressed: () =>
                                    _hymnController.toggleFavorite(hymn),
                                onMusicPressed: () =>
                                    _showAudioPlayerDialog(hymn),
                              )
                                  .animate()
                                  .fadeIn(
                                  duration: 400.ms,
                                  delay: (50 * index).clamp(0, 500).ms)
                                  .slideY(
                                  begin: 0.2,
                                  end: 0,
                                  curve: Curves.easeOutQuad,
                                  duration: 400.ms);
                            },
                            childCount: hymns.length,
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    // Don't dispose the controller here since it's managed by GetX
    // Just clean up any local resources
    super.dispose();
  }
}
