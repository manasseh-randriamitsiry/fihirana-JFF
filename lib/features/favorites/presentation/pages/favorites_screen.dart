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
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
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
    final colors = Theme.of(context).colorScheme;
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
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
                if (snapshot.hasError) {
                  return AppEmptyState(
                    icon: Icons.cloud_off_rounded,
                    title: context.translate((l) => l.unableToLoadFavorites),
                    message:
                        context.translate((l) => l.checkConnectionAndTryAgain),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final favorites = snapshot.data!;
                WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _checkAudioFor(favorites.take(20)));
                final matching = _query.isEmpty
                    ? favorites
                    : favorites
                        .where(
                          (hymn) =>
                              hymn.hymnNumber.toLowerCase().contains(_query) ||
                              hymn.title.toLowerCase().contains(_query),
                        )
                        .toList(growable: false);
                if (favorites.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.favorite_border_rounded,
                    title: context.translate((l) => l.noHymnsAddedYet),
                    message: context.translate((l) => l.savedHymnsWillAppear),
                  );
                }
                if (matching.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.search_off_rounded,
                    title: context.translate((l) => l.noResults),
                  );
                }
                return ListView.separated(
                  key: const PageStorageKey('favorites_list'),
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  itemCount: matching.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final hymn = matching[index];
                    return Obx(
                      () => HymnListItem(
                        key: ValueKey(hymn.id),
                        hymn: hymn,
                        textColor: colors.onSurface,
                        backgroundColor: colors.surface,
                        primaryColor: colors.primary,
                        isFavorite: true,
                        hasAudio: _audioAvailability[hymn.id] ?? false,
                        onFavoritePressed: () =>
                            _hymnService.toggleFavorite(hymn),
                        onMusicPressed: () => _openPlayer(hymn),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
