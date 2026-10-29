import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fihirana/core/navigation/shell_controller.dart';
import 'package:fihirana/features/audio/data/services/audio_service.dart';
import 'package:fihirana/features/audio/presentation/pages/audio_player_screen.dart';
import 'package:fihirana/features/hymn/data/services/hymn_service.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/hymn/presentation/widgets/hymn_list_item.dart';
import 'package:fihirana/shared/widgets/common/app_ui.dart';
import 'package:fihirana/shared/widgets/common/localization_extension.dart';
import 'package:fihirana/core/design_system/app_scale.dart';
import 'package:fihirana/core/design_system/components/app_state_view.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final HymnService _hymnService = HymnService();
  final AudioService _audioService = AudioService.instance;
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _checkedAudio = <String>{};
  final RxMap<String, bool> _audioAvailability = <String, bool>{}.obs;
  Timer? _searchDebounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _hymnService.refreshFavorites());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(AppScale.durShort, () {
      if (mounted) setState(() => _query = value.trim().toLowerCase());
    });
  }

  Future<void> _checkAudioFor(Iterable<Hymn> hymns) async {
    final ids = hymns
        .map((hymn) => hymn.id)
        .where(_checkedAudio.add)
        .toList(growable: false);
    if (ids.isEmpty) return;
    final availability = await _audioService.checkAudioFilesExist(ids);
    if (mounted) _audioAvailability.addAll(availability);
  }

  void _openPlayer(Hymn hymn) {
    AudioPlayerNavigator.navigateToEnhancedPlayer(
      context,
      hymn: hymn,
      playlist: null,
      initialIndex: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: context.translate((l) => l.favorites),
      leading: IconButton(
        tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
        onPressed: Get.find<ShellController>().toggleDrawer,
        icon: const Icon(Icons.menu_rounded),
      ),
      body: Column(
        children: [
          AppSection(
            title: context.translate((l) => l.favoriteHymns),
            padding: const EdgeInsets.fromLTRB(AppScale.gutter,
                AppScale.space16, AppScale.gutter, AppScale.space12),
            child: AppSearchField(
              controller: _searchController,
              hintText: context.translate((l) => l.searchHymnsHint),
              onChanged: _onSearchChanged,
              onClear: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Hymn>>(
              stream: _hymnService.getFavoriteHymnsStream(),
              builder: (context, snapshot) {
                final bool hasData = snapshot.hasData;
                final favorites = hasData ? snapshot.data! : const <Hymn>[];
                if (hasData) {
                  WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _checkAudioFor(favorites.take(20)));
                }
                final matching = _query.isEmpty
                    ? favorites
                    : favorites
                        .where(
                          (hymn) =>
                              hymn.hymnNumber.toLowerCase().contains(_query) ||
                              hymn.title.toLowerCase().contains(_query),
                        )
                        .toList(growable: false);
                final bool noFavorites = favorites.isEmpty;
                final AppState state = snapshot.hasError
                    ? AppState.error
                    : !hasData
                        ? AppState.loading
                        : (noFavorites || matching.isEmpty)
                            ? AppState.empty
                            : AppState.full;

                return AppStateView(
                  state: state,
                  errorTitle: context.translate((l) => l.unableToLoadFavorites),
                  errorMessage:
                      context.translate((l) => l.checkConnectionAndTryAgain),
                  onRetry: () => _hymnService.refreshFavorites(),
                  emptyTitle: noFavorites
                      ? context.translate((l) => l.noHymnsAddedYet)
                      : context.translate((l) => l.noResults),
                  emptyMessage: noFavorites
                      ? context.translate((l) => l.savedHymnsWillAppear)
                      : null,
                  emptyIcon: noFavorites
                      ? Icons.favorite_border_rounded
                      : Icons.search_off_rounded,
                  child: ListView.separated(
                    key: const PageStorageKey('favorites_list'),
                    padding: const EdgeInsets.fromLTRB(AppScale.gutter,
                        AppScale.space8, AppScale.gutter, AppScale.space24),
                    itemCount: matching.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppScale.buttonGap),
                    itemBuilder: (context, index) {
                      final hymn = matching[index];
                      return Obx(
                        () => HymnListItem(
                          key: ValueKey(hymn.id),
                          hymn: hymn,
                          isFavorite: true,
                          hasAudio: _audioAvailability[hymn.id] ?? false,
                          onFavoritePressed: () =>
                              _hymnService.toggleFavorite(hymn),
                          onMusicPressed: () => _openPlayer(hymn),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
