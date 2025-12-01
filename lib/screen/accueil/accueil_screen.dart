
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../controller/color_controller.dart';
import '../../controller/hymn_controller.dart';
import '../../models/hymn.dart';
import '../../services/audio/audio_service.dart';
import '../../services/core/version_check_service.dart';
import '../../utility/navigation_utility.dart';
import '../../widgets/accueil/accueil_action_widgets.dart';
import '../../widgets/common/localization_extension.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/hymn/hymn_list_item.dart';
import '../../widgets/hymn/hymn_search_field.dart';
import '../../widgets/language_picker_widget.dart';
import '../../widgets/skeleton_hymn_list.dart';
import '../player/audio_player_screen.dart';

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
    _hymnController =
        Get.put<HymnController>(HymnController(), permanent: true);

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
                  '${context.translate((l) => l.errorDownloadingUpdate)}: ${e
                      .toString()}'),
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
      builder: (colorController) =>
          Obx(() {
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
                    onPressed:
                    _isDownloading ? null : _downloadAndInstallUpdate,
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
    _checkedHymnIds.clear();
    // Don't dispose the controller here since it's managed by GetX
    // Just clean up any local resources
    super.dispose();
  }
}
