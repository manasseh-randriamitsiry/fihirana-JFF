import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/core/navigation/shell_controller.dart';
import 'package:fihirana/features/playlist/presentation/controllers/playlist_controller.dart';
import 'package:fihirana/core/init/lazy_service_manager.dart';
import 'package:fihirana/features/playlist/domain/entities/playlist.dart';
import 'package:fihirana/features/playlist/presentation/widgets/playlist_item_card.dart';
import 'package:fihirana/features/playlist/presentation/widgets/create_playlist_dialog.dart';
import 'package:fihirana/features/playlist/presentation/pages/playlist_detail_screen.dart';
import 'package:fihirana/shared/widgets/common/localization_extension.dart';
import 'package:fihirana/l10n/app_localizations.dart';

class PlaylistListScreen extends StatefulWidget {
  const PlaylistListScreen({super.key});

  @override
  State<PlaylistListScreen> createState() => _PlaylistListScreenState();
}

class _PlaylistListScreenState extends State<PlaylistListScreen> {
  PlaylistController? _playlistController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadController();
  }

  Future<void> _loadController() async {
    try {
      final controller = await lazyServiceManager.playlistController;
      if (mounted) {
        setState(() {
          _playlistController = controller;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      // Handle error - perhaps show a snackbar or retry
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ColorController colorController = Get.find<ColorController>();

    if (_isLoading || _playlistController == null) {
      return Scaffold(
        backgroundColor: colorController.backgroundColor.value,
        appBar: AppBar(
          title: Text(
            context.translate((l) => l.myPlaylists),
            style: TextStyle(color: colorController.textColor.value),
          ),
          backgroundColor: colorController.backgroundColor.value,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.menu_rounded, color: colorController.iconColor.value),
            onPressed: () => Get.find<ShellController>().toggleDrawer(),
          ),
          iconTheme: IconThemeData(color: colorController.iconColor.value),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: colorController.primaryColor.value,
          ),
        ),
      );
    }

    final playlistController = _playlistController!;

    return Scaffold(
      backgroundColor: colorController.backgroundColor.value,
      appBar: AppBar(
title: Text(
          context.translate((l) => l.myPlaylists),
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
          key: const PageStorageKey('playlists_list'),
          padding: const EdgeInsets.all(16),
          itemCount: playlistController.playlists.length,
          itemBuilder: (context, index) {
            final playlist = playlistController.playlists[index];
            return PlaylistItemCard(
              key: ValueKey(playlist.id),
              playlist: playlist,
              onTap: () => Get.to(() => PlaylistDetailScreen(playlistId: playlist.id)),
              onShare: () => playlistController.sharePlaylist(playlist.id),
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
        title: context.translate((l) => l.newPlaylist),
        hint: context.translate((l) => l.playlistExampleHint),
        onCreate: (title, date) {
          _playlistController?.createPlaylist(title, date);
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
          context.translate((l) => l.deletePlaylist),
          style: TextStyle(color: colorController.textColor.value),
        ),
        content: Text(
          context.translate((l) => l.confirmDeletePlaylist(playlist.title)),
          style: TextStyle(color: colorController.textColor.value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.translate((l) => l.cancel),
                style: TextStyle(color: colorController.textColor.value)),
          ),
          TextButton(
            onPressed: () {
              _playlistController?.deletePlaylist(playlist.id);
              Navigator.pop(context);
            },
            child: Text(context.translate((l) => l.delete), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
