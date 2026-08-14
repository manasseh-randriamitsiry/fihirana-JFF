import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fihirana/features/hymn/data/services/hymn_service.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/hymn/presentation/pages/hymn_detail_screen.dart';
import 'package:fihirana/features/playlist/di/playlist_di.dart';
import 'package:fihirana/features/playlist/presentation/controllers/playlist_controller.dart';
import 'package:fihirana/features/playlist/presentation/widgets/playlist_detail_widgets.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/shared/widgets/common/app_ui.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  late final PlaylistController _playlistController;

  @override
  void initState() {
    super.initState();
    try {
      _playlistController = PlaylistDI.playlistController;
    } catch (_) {
      PlaylistDI.initialize();
      _playlistController = PlaylistDI.playlistController;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hymnService = Get.find<HymnService>();
    final l10n = AppLocalizations.of(context);

    return Obx(() {
      final playlist = _playlistController.playlists
          .firstWhereOrNull((item) => item.id == widget.playlistId);
      if (playlist == null) {
        return AppPageScaffold(
          title: l10n.playlistNotFound,
          body: AppEmptyState(
            icon: Icons.playlist_remove_rounded,
            title: l10n.playlistNotFound,
          ),
        );
      }

      return AppPageScaffold(
        title: playlist.title,
        actions: [
          IconButton(
            tooltip: l10n.share,
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _playlistController.sharePlaylist(playlist.id),
          ),
        ],
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: AppGroupedSurface(
                children: [
                  PlaylistHeaderInfo(
                    date: playlist.date,
                    hymnCount: playlist.hymnIds.length,
                    onDateChanged: (date) => _playlistController
                        .updatePlaylistDate(playlist.id, date),
                  ),
                ],
              ),
            ),
            Expanded(
              child: playlist.hymnIds.isEmpty
                  ? AppEmptyState(
                      icon: Icons.queue_music_rounded,
                      title: l10n.noHymnsAddedYet,
                    )
                  : FutureBuilder<List<Hymn>>(
                      key: ValueKey(playlist.hymnIds.length),
                      future: hymnService.getHymnsByIds(playlist.hymnIds),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return AppEmptyState(
                            icon: Icons.error_outline_rounded,
                            title: l10n.errorLoadingHymns,
                          );
                        }

                        final hymns = snapshot.data ?? [];
                        return ListView.builder(
                          key: const PageStorageKey('playlist_hymns_list'),
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          itemCount: hymns.length,
                          itemBuilder: (context, index) {
                            final hymn = hymns[index];
                            return PlaylistHymnItem(
                              key: ValueKey(hymn.id),
                              hymn: hymn,
                              index: index,
                              onTap: () => Get.to(
                                () => HymnDetailScreen(hymnId: hymn.id),
                              ),
                              onRemove: () => _playlistController
                                  .removeHymnFromPlaylist(playlist.id, hymn.id),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    });
  }
}
