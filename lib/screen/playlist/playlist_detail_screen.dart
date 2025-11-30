import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/color_controller.dart';
import '../../controller/playlist_controller.dart';
import 'package:fihirana/services/features/hymn_service.dart';
import '../../models/hymn.dart';
import '../hymn/hymn_detail_screen.dart';
import '../../widgets/playlist/playlist_detail_widgets.dart';
import '../../l10n/app_localizations.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context) {
    final ColorController colorController = Get.find();
    final PlaylistController playlistController = Get.find();
    final HymnService hymnService = Get.find();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorController.backgroundColor.value,
      body: Obx(() {
        // Find the current playlist from the controller
        final playlist = playlistController.playlists
            .firstWhereOrNull((p) => p.id == playlistId);

        if (playlist == null) {
          return Scaffold(
            backgroundColor: colorController.backgroundColor.value,
            appBar: AppBar(
              title: Text(l10n.playlistNotFound),
              backgroundColor: colorController.backgroundColor.value,
            ),
            body: Center(child: Text(l10n.playlistNotFound)),
          );
        }

        return Scaffold(
          backgroundColor: colorController.backgroundColor.value,
          appBar: AppBar(
            title: Text(
              playlist.title,
              style: TextStyle(color: colorController.textColor.value),
            ),
            backgroundColor: colorController.backgroundColor.value,
            elevation: 0,
            iconTheme: IconThemeData(color: colorController.iconColor.value),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => playlistController.sharePlaylist(playlist),
              ),
            ],
          ),
          body: Column(
            children: [
              // Header Info
              PlaylistHeaderInfo(
                date: playlist.date,
                hymnCount: playlist.hymnIds.length,
                onDateChanged: (date) {
                  playlistController.updatePlaylistDate(playlist.id, date);
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
                            padding: const EdgeInsets.all(16),
                            itemCount: hymns.length,
                            itemBuilder: (context, index) {
                              final hymn = hymns[index];
                              return PlaylistHymnItem(
                                hymn: hymn,
                                index: index,
                                onTap: () {
                                  Get.to(
                                      () => HymnDetailScreen(hymnId: hymn.id));
                                },
                                onRemove: () {
                                  playlistController.removeHymnFromPlaylist(
                                      playlist.id, hymn.id);
                                },
                              );
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
}
