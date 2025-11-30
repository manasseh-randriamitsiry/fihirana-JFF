import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/color_controller.dart';
import '../../controller/shell_controller.dart';
import '../../controller/playlist_controller.dart';
import '../../models/playlist.dart';
import 'playlist_detail_screen.dart';
import '../../widgets/playlist/playlist_item_card.dart';
import '../../widgets/playlist/create_playlist_dialog.dart';
import '../../widgets/common/mlkit_localization_provider.dart';
import '../../l10n/app_localizations.dart';

class PlaylistListScreen extends StatelessWidget {
  const PlaylistListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ColorController colorController = Get.find();
    final PlaylistController playlistController = Get.find();

    return Scaffold(
      backgroundColor: colorController.backgroundColor.value,
      appBar: AppBar(
title: Text(
          context.translateWithMLKit((l) => l.myPlaylists),
          style: TextStyle(color: colorController.textColor.value),
        ),
        backgroundColor: colorController.backgroundColor.value,
        elevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.menu_rounded, color: colorController.iconColor.value),
          onPressed: () => Get.find<ShellController>().toggleDrawer(),
        ),
        iconTheme: IconThemeData(color: colorController.iconColor.value),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreatePlaylistDialog(context),
          ),
        ],
      ),
      body: Obx(() {
        if (playlistController.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              color: colorController.primaryColor.value,
            ),
          );
        }

        if (playlistController.playlists.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.playlist_play,
                  size: 64,
                  color: colorController.textColor.value.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.noPlaylistsYet,
                  style: TextStyle(
                    fontSize: 18,
                    color:
                        colorController.textColor.value.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _showCreatePlaylistDialog(context),
                  child: Text(
                    l10n.createFirstPlaylist,
                    style: TextStyle(
                      color: colorController.primaryColor.value,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: playlistController.playlists.length,
          itemBuilder: (context, index) {
            final playlist = playlistController.playlists[index];
            return PlaylistItemCard(
              playlist: playlist,
              onTap: () => Get.to(() => PlaylistDetailScreen(playlistId: playlist.id)),
              onShare: () => playlistController.sharePlaylist(playlist),
              onDelete: () => _confirmDelete(context, playlist),
            );
          },
        );
      }),
    );
  }



  void _showCreatePlaylistDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CreatePlaylistDialog(
        title: context.translateWithMLKit((l) => l.newPlaylist),
        hint: context.translateWithMLKit((l) => l.playlistExampleHint),
        onCreate: (title, date) {
          Get.find<PlaylistController>().createPlaylist(title, date);
        },
      ),
    );
  }

void _confirmDelete(BuildContext context, Playlist playlist) {
    final ColorController colorController = Get.find();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorController.backgroundColor.value,
        title: Text(
          context.translateWithMLKit((l) => l.deletePlaylist),
          style: TextStyle(color: colorController.textColor.value),
        ),
        content: Text(
          context.translateWithMLKit((l) => l.confirmDeletePlaylist(playlist.title)),
          style: TextStyle(color: colorController.textColor.value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.translateWithMLKit((l) => l.cancel),
                style: TextStyle(color: colorController.textColor.value)),
          ),
          TextButton(
            onPressed: () {
              Get.find<PlaylistController>().deletePlaylist(playlist.id);
              Navigator.pop(context);
            },
            child: Text(context.translateWithMLKit((l) => l.delete), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
