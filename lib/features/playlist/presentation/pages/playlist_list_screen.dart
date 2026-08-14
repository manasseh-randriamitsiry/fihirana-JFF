import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fihirana/core/navigation/shell_controller.dart';
import 'package:fihirana/features/playlist/di/playlist_di.dart';
import 'package:fihirana/features/playlist/domain/entities/playlist.dart';
import 'package:fihirana/features/playlist/presentation/pages/playlist_detail_screen.dart';
import 'package:fihirana/features/playlist/presentation/widgets/create_playlist_dialog.dart';
import 'package:fihirana/features/playlist/presentation/widgets/playlist_item_card.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/shared/widgets/common/app_ui.dart';
import 'package:fihirana/shared/widgets/common/localization_extension.dart';

class PlaylistListScreen extends StatelessWidget {
  const PlaylistListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final playlistController = PlaylistDI.playlistController;
    return AppPageScaffold(
      title: context.translate((l) => l.myPlaylists),
      leading: IconButton(
        tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
        icon: const Icon(Icons.menu_rounded),
        onPressed: Get.find<ShellController>().toggleDrawer,
      ),
      actions: [
        IconButton(
          tooltip: l10n.newPlaylist,
          icon: const Icon(Icons.add_rounded),
          onPressed: () => _showCreatePlaylistDialog(context),
        ),
      ],
      body: Obx(() {
        if (playlistController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (playlistController.playlists.isEmpty) {
          return AppEmptyState(
            icon: Icons.playlist_play_rounded,
            title: l10n.noPlaylistsYet,
            message: 'Organize hymns for worship, practice, or sharing.',
            action: FilledButton(
              onPressed: () => _showCreatePlaylistDialog(context),
              child: Text(l10n.createFirstPlaylist),
            ),
          );
        }
        return ListView.separated(
          key: const PageStorageKey('playlists_list'),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          itemCount: playlistController.playlists.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final playlist = playlistController.playlists[index];
            return PlaylistItemCard(
              key: ValueKey(playlist.id),
              playlist: playlist,
              onTap: () =>
                  Get.to(() => PlaylistDetailScreen(playlistId: playlist.id)),
              onShare: () => playlistController.sharePlaylist(playlist.id),
              onDelete: () => _confirmDelete(context, playlist),
            );
          },
        );
      }),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final playlistController = PlaylistDI.playlistController;
    showDialog<void>(
      context: context,
      builder: (context) => CreatePlaylistDialog(
        title: context.translate((l) => l.newPlaylist),
        hint: context.translate((l) => l.playlistExampleHint),
        onCreate: playlistController.createPlaylist,
      ),
    );
  }

  void _confirmDelete(BuildContext context, Playlist playlist) {
    final playlistController = PlaylistDI.playlistController;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.translate((l) => l.deletePlaylist)),
        content: Text(
            context.translate((l) => l.confirmDeletePlaylist(playlist.title))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.translate((l) => l.cancel)),
          ),
          TextButton(
            onPressed: () {
              playlistController.deletePlaylist(playlist.id);
              Navigator.pop(dialogContext);
            },
            child: Text(context.translate((l) => l.delete),
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}
