import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/features/hymn/presentation/controllers/hymn_controller.dart';
import 'package:fihirana/features/hymn/data/repositories/hymn_repository_impl.dart';
import 'package:fihirana/features/hymn/data/services/hymn_service.dart';
import 'package:fihirana/features/hymn/domain/usecases/search_hymns_usecase.dart';
import 'package:fihirana/features/hymn/domain/usecases/add_to_favorites_usecase.dart';
import 'package:fihirana/features/hymn/domain/usecases/remove_from_favorites_usecase.dart';
import 'package:fihirana/features/hymn/domain/usecases/is_favorite_usecase.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/audio/data/services/audio_service.dart';
import 'package:fihirana/core/utils/version_check_service.dart';
import 'package:fihirana/core/utils/navigation_utility.dart';
import 'package:fihirana/features/home/presentation/widgets/accueil_action_widgets.dart';
import 'package:fihirana/shared/widgets/common/localization_extension.dart';
import 'package:fihirana/core/constants/app_dimensions.dart';
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
  late final ColorController _colorController;
  bool _updateAvailable = false;
  bool _isDownloading = false;
  final Set<String> _checkedHymnIds = <String>{};
  final RxMap<String, bool> _audioAvailability = <String, bool>{}.obs;

  @override
  void initState() {
    super.initState();
    _colorController = Get.find<ColorController>();
    
    // Initialize the controller properly to avoid disposal issues
    final hymnService = HymnService();
    final hymnRepository = HymnRepositoryImpl(hymnService);
    
    _hymnController = Get.put<HymnController>(HymnController(
      searchHymnsUseCase: SearchHymnsUseCase(hymnRepository),
      addToFavoritesUseCase: AddToFavoritesUseCase(hymnRepository),
      removeFromFavoritesUseCase: RemoveFromFavoritesUseCase(hymnRepository),
      isFavoriteUseCase: IsFavoriteUseCase(hymnRepository),
    ), permanent: true);

    // Initial audio check for first batch of hymns
    _checkInitialAudio();

    VersionCheckService.setOnUpdateAvailableCallback(() {
      if (mounted) {
        setState(() {
          _updateAvailable = true;
        });
      }
    });
  }

  void _checkInitialAudio() async {
    // Wait for hymns to load
    ever(_hymnController.filteredHymns, (hymns) {
      if (hymns.isNotEmpty) {
        _checkAudioForVisibleHymns(hymns.take(20).toList());
      }
    });
  }

  Future<void> _checkAudioForVisibleHymns(List<Hymn> hymns) async {
    final idsToCheck = hymns
        .map((h) => h.id)
        .where((id) => !_checkedHymnIds.contains(id))
        .toList();
    
    if (idsToCheck.isEmpty) return;
    
    _checkedHymnIds.addAll(idsToCheck);
    final results = await AudioService.instance.checkAudioFilesExist(idsToCheck);
    _audioAvailability.addAll(results);
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
      builder: (colorController) {
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
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      widget.openDrawer();
                    },
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
                  HapticFeedback.lightImpact();
                  SimpleLanguagePicker.showLanguagePicker(context);
                },
              ),
              IconButton(
                key: const ValueKey('favorites_button'),
                icon: Icon(Icons.favorite, color: iconColor),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  NavigationUtility.navigateToFavorites();
                },
              ),
            ],
          ),
          body: Column(
            children: [
               Padding(
                padding: const EdgeInsets.all(AppDimensions.md),
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
                child: Obx(() {
                  if (_hymnController.isLoading.value) {
                    return const SkeletonHymnList();
                  }

                  final hymns = _hymnController.filteredHymns;
                  if (hymns.isEmpty) {
                    return EmptyStateWidget(
                      message: context.translate((l) => l.noHymnsFound),
                      icon: Icons.music_off_rounded,
                      actionLabel: context.translate((l) => l.clearSearch),
                      onActionPressed: () {
                        if (!_hymnController.isDisposed) {
                          _hymnController.safeSearchController.clear();
                        }
                      },
                    );
                  }

                  return ListView.builder(
                    key: const PageStorageKey('home_hymns_list'),
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppDimensions.md),
                    itemCount: hymns.length,
                    itemBuilder: (context, index) {
                      final hymn = hymns[index];

                      // Batch check audio for next items as we scroll
                      if (index > 0 && index % 15 == 0) {
                        final nextBatch =
                            hymns.skip(index).take(20).toList();
                        _checkAudioForVisibleHymns(nextBatch);
                      }

                      return Obx(() {
                        final isFavorite = _hymnController
                                .favoriteStatuses[hymn.id]?.isNotEmpty ??
                            false;
                        final hasAudio =
                            _audioAvailability[hymn.id] ?? false;

                        return HymnListItem(
                          key: ValueKey(hymn.id),
                          hymn: hymn,
                          textColor: textColor,
                          backgroundColor: backgroundColor,
                          primaryColor: _colorController.primaryColor.value,
                          isFavorite: isFavorite,
                          hasAudio: hasAudio,
                          onFavoritePressed: () =>
                              _hymnController.toggleFavorite(hymn),
                          onMusicPressed: () => _showAudioPlayerDialog(hymn),
                        );
                      })
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
                }),
              ),
            ],
          ),
        );
      }
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
