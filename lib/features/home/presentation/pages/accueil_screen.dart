import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/features/hymn/presentation/controllers/hymn_controller.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/audio/data/services/audio_service.dart';
import 'package:fihirana/core/utils/version_check_service.dart';
import 'package:fihirana/core/utils/navigation_utility.dart';
import 'package:fihirana/features/home/presentation/widgets/accueil_action_widgets.dart';
import 'package:fihirana/shared/widgets/common/localization_extension.dart';
import 'package:fihirana/shared/widgets/common/empty_state_widget.dart';
import 'package:fihirana/features/hymn/presentation/widgets/hymn_list_item.dart';
import 'package:fihirana/features/hymn/presentation/widgets/hymn_search_field.dart';
import 'package:fihirana/features/audio/presentation/pages/audio_player_screen.dart';
import 'package:fihirana/shared/widgets/common/simple_language_picker.dart';
import 'package:fihirana/shared/widgets/common/skeleton_hymn_list.dart';

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
  StreamSubscription? _hymnSubscription;

  @override
  void initState() {
    super.initState();
    // Initialize the controller properly to avoid disposal issues
    _hymnController =
        Get.put<HymnController>(HymnController(), permanent: true);

    // Listen to hymn updates to perform batch checks safely
    _hymnSubscription = _hymnController.hymnsStream.listen(_onHymnsUpdated);

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

  void _showCurrentPlayingDialog() {
    final audioService = AudioService.instance;
    final currentHymn = audioService.currentHymn;

    if (currentHymn != null && context.mounted) {
      _showAudioPlayerDialog(currentHymn);
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

  void _onHymnsUpdated(List<Hymn> hymns) {
    if (!mounted) return;

    // Check first 10 items
    final List<Hymn> firstTen =
        hymns.length >= 10 ? hymns.sublist(0, 10) : hymns;
    _batchCheckAudioFiles(firstTen);

    // Preload common hymns
    _preloadCommonHymns(hymns);
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${context.translate((l) => l.errorDownloadingUpdate)}: ${e.toString()}'),
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

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: backgroundColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: widget.showMenuButton
                ? IconButton(
                    key: const ValueKey('menu_button'),
                    icon: Icon(Icons.menu, color: iconColor),
                    onPressed: widget.openDrawer,
                  )
                : null,
            title: Text(
              context.translate((l) => l.appTitleShort),
              style: defaultTextStyle.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 26,
              ),
            ),
            actions: [
              UpdateButtonWidget(
                isDownloading: _isDownloading,
                updateAvailable: _updateAvailable,
                onPressed: _isDownloading ? null : _downloadAndInstallUpdate,
              ),
              Obx(() {
                final audioService = AudioService.instance;
                final currentHymnId = audioService.currentPlayingHymnId;
                final isPlaying =
                    currentHymnId.isNotEmpty && audioService.isPlaying;

                return NowPlayingButtonWidget(
                  currentHymnId: currentHymnId,
                  isPlaying: isPlaying,
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
                    builder: (context) => const SimpleLanguagePickerDialog(),
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
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: HymnSearchField(
                  controller: _hymnController.safeSearchController,
                  defaultTextStyle: defaultTextStyle,
                  textColor: textColor,
                  iconColor: iconColor,
                  backgroundColor: backgroundColor,
                  onChanged: () {
                    if (mounted && !_hymnController.isDisposed) {
                      setState(() {});
                    }
                  },
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Hymn>>(
                  stream: _hymnController.hymnsStream,
                  builder: (context, snapshot) {
                    // Early return if widget is not mounted
                    if (!mounted) return const SizedBox.shrink();
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          context.translate((l) => l.errorOccurredWithDetails(
                              snapshot.error.toString())),
                          style: defaultTextStyle,
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SkeletonHymnList();
                    }

                    final hymns =
                        _hymnController.filterHymnList(snapshot.data ?? []);
                    if (hymns.isEmpty) {
                      return EmptyStateWidget(
                        message: context.translate((l) => l.noHymnsFound),
                        icon: Icons.music_off_rounded,
                        actionLabel: context.translate((l) => l.clearSearch),
                        onActionPressed: () {
                          if (!_hymnController.isDisposed) {
                            _hymnController.safeSearchController.clear();
                            // Trigger rebuild/search update if needed, though controller listener should handle it
                            setState(() {});
                          }
                        },
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: hymns.length,
                      itemBuilder: (context, index) {
                        final hymn = hymns[index];
                        return HymnListItem(
                          key: ValueKey(hymn.id),
                          hymn: hymn,
                          textColor: textColor,
                          backgroundColor: backgroundColor,
                          onFavoritePressed: () =>
                              _hymnController.toggleFavorite(hymn),
                          onMusicPressed: () => _showAudioPlayerDialog(hymn),
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
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    // Cancel any pending operations
    _hymnSubscription?.cancel();
    _checkedHymnIds.clear();
    // Don't dispose the controller here since it's managed by GetX
    // Just clean up any local resources
    super.dispose();
  }
}
