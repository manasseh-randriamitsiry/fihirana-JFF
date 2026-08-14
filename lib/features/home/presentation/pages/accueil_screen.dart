import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fihirana/core/utils/navigation_utility.dart';
import 'package:fihirana/core/utils/version_check_service.dart';
import 'package:fihirana/features/audio/data/services/audio_service.dart';
import 'package:fihirana/features/audio/presentation/pages/audio_player_screen.dart';
import 'package:fihirana/features/hymn/data/repositories/hymn_repository_impl.dart';
import 'package:fihirana/features/hymn/data/services/hymn_service.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/hymn/domain/usecases/add_to_favorites_usecase.dart';
import 'package:fihirana/features/hymn/domain/usecases/is_favorite_usecase.dart';
import 'package:fihirana/features/hymn/domain/usecases/remove_from_favorites_usecase.dart';
import 'package:fihirana/features/hymn/domain/usecases/search_hymns_usecase.dart';
import 'package:fihirana/features/hymn/presentation/controllers/hymn_controller.dart';
import 'package:fihirana/features/hymn/presentation/widgets/hymn_list_item.dart';
import 'package:fihirana/features/hymn/presentation/widgets/hymn_search_field.dart';
import 'package:fihirana/features/home/presentation/widgets/accueil_action_widgets.dart';
import 'package:fihirana/shared/widgets/common/app_ui.dart';
import 'package:fihirana/shared/widgets/common/localization_extension.dart';
import 'package:fihirana/shared/widgets/common/simple_language_picker.dart';
import 'package:fihirana/shared/widgets/common/skeleton_hymn_list.dart';

class AccueilScreen extends StatefulWidget {
  final VoidCallback openDrawer;
  final bool showMenuButton;

  const AccueilScreen({
    super.key,
    required this.openDrawer,
    this.showMenuButton = true,
  });

  @override
  State<AccueilScreen> createState() => _AccueilScreenState();
}

class _AccueilScreenState extends State<AccueilScreen> {
  late final HymnController _hymnController;
  final AudioService _audioService = AudioService.instance;
  final ScrollController _scrollController = ScrollController();
  final Set<String> _checkedHymnIds = <String>{};
  final RxMap<String, bool> _audioAvailability = <String, bool>{}.obs;
  Worker? _hymnListWorker;
  bool _updateAvailable = false;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _hymnController = _getHymnController();
    _hymnListWorker = ever<List<Hymn>>(
      _hymnController.filteredHymns,
      (hymns) => _checkAudioForHymns(hymns.take(16)),
    );
    _scrollController.addListener(_loadAudioNearViewport);
    VersionCheckService.setOnUpdateAvailableCallback(() {
      if (mounted) setState(() => _updateAvailable = true);
    });
  }

  HymnController _getHymnController() {
    if (Get.isRegistered<HymnController>()) return Get.find<HymnController>();
    final repository = HymnRepositoryImpl(HymnService());
    return Get.put(
      HymnController(
        searchHymnsUseCase: SearchHymnsUseCase(repository),
        addToFavoritesUseCase: AddToFavoritesUseCase(repository),
        removeFromFavoritesUseCase: RemoveFromFavoritesUseCase(repository),
        isFavoriteUseCase: IsFavoriteUseCase(repository),
      ),
      permanent: true,
    );
  }

  void _loadAudioNearViewport() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > 840) {
      return;
    }
    final startIndex = (_scrollController.offset / 82)
        .floor()
        .clamp(0, _hymnController.filteredHymns.length);
    _checkAudioForHymns(
        _hymnController.filteredHymns.skip(startIndex).take(20));
  }

  Future<void> _checkAudioForHymns(Iterable<Hymn> hymns) async {
    final ids = hymns
        .map((hymn) => hymn.id)
        .where(_checkedHymnIds.add)
        .toList(growable: false);
    if (ids.isEmpty) return;
    final results = await _audioService.checkAudioFilesExist(ids);
    if (mounted) _audioAvailability.addAll(results);
  }

  void _showAudioPlayer(Hymn hymn) {
    AudioPlayerNavigator.navigateToEnhancedPlayer(
      context,
      hymn: hymn,
      playlist: null,
      initialIndex: null,
    );
  }

  Future<void> _openNowPlaying() async {
    final current = _audioService.currentHymn;
    if (current != null) {
      _showAudioPlayer(current);
      return;
    }
    final hymns = _hymnController.filteredHymns;
    if (hymns.isNotEmpty) _showAudioPlayer(hymns.first);
  }

  Future<void> _downloadAndInstallUpdate() async {
    setState(() => _isDownloading = true);
    try {
      await VersionCheckService.downloadAndInstallLatestVersion();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(context.translate((l) => l.errorDownloadingUpdate))),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  void dispose() {
    _hymnListWorker?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppPageScaffold(
      title: context.translate((l) => l.appTitleShort),
      largeTitle: true,
      leading: widget.showMenuButton
          ? IconButton(
              key: const ValueKey('menu_button'),
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              onPressed: widget.openDrawer,
              icon: const Icon(Icons.menu_rounded),
            )
          : null,
      actions: [
        if (_updateAvailable)
          UpdateButtonWidget(
            isDownloading: _isDownloading,
            updateAvailable: true,
            onPressed: _isDownloading ? null : _downloadAndInstallUpdate,
          ),
        Obx(
          () => NowPlayingButtonWidget(
            currentHymnId: _audioService.currentPlayingHymnId,
            isPlaying: _audioService.isPlaying,
            onPressed: _openNowPlaying,
          ),
        ),
        PopupMenuButton<String>(
          tooltip: context.translate((l) => l.moreActions),
          onSelected: (value) {
            if (value == 'language') {
              SimpleLanguagePicker.showLanguagePicker(context);
            } else if (value == 'favorites') {
              NavigationUtility.navigateToFavorites();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'language',
              child: Row(
                children: [
                  const Icon(Icons.language_rounded),
                  const SizedBox(width: 12),
                  Text(context.translate((l) => l.language)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'favorites',
              child: Row(
                children: [
                  const Icon(Icons.favorite_border_rounded),
                  const SizedBox(width: 12),
                  Text(context.translate((l) => l.favorites)),
                ],
              ),
            ),
          ],
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: HymnSearchField(
              controller: _hymnController.searchController,
              defaultTextStyle: Theme.of(context).textTheme.bodyLarge!,
              textColor: colors.onSurface,
              iconColor: colors.onSurfaceVariant,
              backgroundColor: colors.surfaceContainerHighest,
              onChanged: () {},
            ),
          ),
          Expanded(
            child: Obx(() {
              if (_hymnController.isLoading.value) {
                return const SkeletonHymnList();
              }
              final hymns = _hymnController.filteredHymns;
              if (hymns.isEmpty) {
                return AppEmptyState(
                  icon: Icons.music_off_rounded,
                  title: context.translate((l) => l.noHymnsFound),
                  message: 'Try a hymn number, title, or lyric.',
                  action: TextButton(
                    onPressed: _hymnController.searchController.clear,
                    child: Text(context.translate((l) => l.clearSearch)),
                  ),
                );
              }
              return ListView.separated(
                key: const PageStorageKey('home_hymns_list'),
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: hymns.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final hymn = hymns[index];
                  return Obx(
                    () => HymnListItem(
                      key: ValueKey(hymn.id),
                      hymn: hymn,
                      textColor: colors.onSurface,
                      backgroundColor: colors.surface,
                      primaryColor: colors.primary,
                      isFavorite: _hymnController
                              .favoriteStatuses[hymn.id]?.isNotEmpty ??
                          false,
                      hasAudio: _audioAvailability[hymn.id] ?? false,
                      onFavoritePressed: () =>
                          _hymnController.toggleFavorite(hymn),
                      onMusicPressed: () => _showAudioPlayer(hymn),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
