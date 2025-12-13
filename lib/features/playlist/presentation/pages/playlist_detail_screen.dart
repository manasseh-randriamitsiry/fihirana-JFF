import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/features/playlist/presentation/controllers/playlist_controller.dart';
import 'package:fihirana/features/playlist/di/playlist_di.dart';
import 'package:fihirana/features/hymn/data/services/hymn_service.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/hymn/presentation/pages/hymn_detail_screen.dart';
import 'package:fihirana/features/playlist/presentation/widgets/playlist_detail_widgets.dart';
import 'package:fihirana/l10n/app_localizations.dart';

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
    
    // Synchronous initialization for instant loading
    try {
      _playlistController = PlaylistDI.playlistController;
    } catch (e) {
      PlaylistDI.initialize();
      _playlistController = PlaylistDI.playlistController;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorController colorController = Get.find();
    final HymnService hymnService = Get.find();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colorController.backgroundColor.value,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Obx(() {
          final playlist = _playlistController.playlists
              .firstWhereOrNull((p) => p.id == widget.playlistId);
          
          return AppBar(
            title: Text(
              playlist?.title ?? l10n.playlistNotFound,
              style: TextStyle(color: colorController.textColor.value),
            ),
            backgroundColor: colorController.backgroundColor.value,
            elevation: 0,
            iconTheme: IconThemeData(color: colorController.iconColor.value),
            actions: playlist != null
                ? [
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () => _playlistController.sharePlaylist(playlist.id),
                    ),
                  ]
                : [],
          );
        }),
      ),
      body: Obx(() {
        final playlist = _playlistController.playlists
            .firstWhereOrNull((p) => p.id == widget.playlistId);

        if (playlist == null) {
          return Center(child: Text(l10n.playlistNotFound));
        }

        return Column(
          children: [
            // Header Info
            PlaylistHeaderInfo(
              date: playlist.date,
              hymnCount: playlist.hymnIds.length,
              onDateChanged: (date) {
                _playlistController.updatePlaylistDate(playlist.id, date);
              },
            ),

            // Hymn List
            Expanded(
              child: playlist.hymnIds.isEmpty
                  ? Center(
                      child: Text(
                        l10n.noHymnsAddedYet,
                        style: TextStyle(
                          color: colorController.textColor.value
                              .withValues(alpha: 0.5),
                          fontSize: 16,
                        ),
                      ),
                    )
                  : FutureBuilder<List<Hymn>>(
                      key: ValueKey(playlist.hymnIds
                          .length), // Force rebuild when count changes
                      future: hymnService.getHymnsByIds(playlist.hymnIds),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: colorController.primaryColor.value,
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              l10n.errorLoadingHymns,
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        }

                        final hymns = snapshot.data ?? [];

                        return ListView.builder(
                          key: const PageStorageKey('playlist_hymns_list'),
                          padding: const EdgeInsets.all(16),
                          itemCount: hymns.length,
                          itemBuilder: (context, index) {
                            final hymn = hymns[index];
                            return PlaylistHymnItem(
                              key: ValueKey(hymn.id),
                              hymn: hymn,
                              index: index,
                              onTap: () {
                                Get.to(
                                    () => HymnDetailScreen(hymnId: hymn.id));
                              },
                              onRemove: () {
                                _playlistController.removeHymnFromPlaylist(
                                    playlist.id, hymn.id);
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }
}
