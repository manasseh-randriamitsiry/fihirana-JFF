import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controller/color_controller.dart';
import '../../controller/playlist_controller.dart';
import '../../models/playlist.dart';
import 'playlist_detail_screen.dart';
import '../../l10n/app_localizations.dart';

class PlaylistListScreen extends StatelessWidget {
  const PlaylistListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorController colorController = Get.find();
    final PlaylistController playlistController = Get.find();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorController.backgroundColor.value,
      appBar: AppBar(
        title: Text(
          l10n.myPlaylists,
          style: TextStyle(color: colorController.textColor.value),
        ),
        backgroundColor: colorController.backgroundColor.value,
        elevation: 0,
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
            return _buildPlaylistItem(context, playlist, colorController, l10n);
          },
        );
      }),
    );
  }

  Widget _buildPlaylistItem(BuildContext context, Playlist playlist,
      ColorController colorController, AppLocalizations l10n) {
    final dateFormat = DateFormat('EEE, MMM d, yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorController.backgroundColor.value,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorController.textColor.value.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colorController.textColor.value.withValues(alpha: 0.1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () {
          Get.to(() => PlaylistDetailScreen(playlistId: playlist.id));
        },
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: colorController.primaryColor.value.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.music_note,
            color: colorController.primaryColor.value,
          ),
        ),
        title: Text(
          playlist.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: colorController.textColor.value,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              dateFormat.format(playlist.date),
              style: TextStyle(
                color: colorController.textColor.value.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${playlist.hymnIds.length} hymns',
              style: TextStyle(
                color: colorController.textColor.value.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: colorController.iconColor.value,
          ),
          onSelected: (value) {
            if (value == 'share') {
              Get.find<PlaylistController>().sharePlaylist(playlist);
            } else if (value == 'delete') {
              _confirmDelete(context, playlist);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  const Icon(Icons.share, size: 20),
                  const SizedBox(width: 12),
                  Text(l10n.share),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, color: Colors.red, size: 20),
                  const SizedBox(width: 12),
                  Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final titleController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    final ColorController colorController = Get.find();
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: colorController.backgroundColor.value,
            title: Text(
              l10n.newPlaylist,
              style: TextStyle(color: colorController.textColor.value),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: TextStyle(color: colorController.textColor.value),
                  decoration: InputDecoration(
                    labelText: l10n.title,
                    hintText: l10n.playlistExampleHint,
                    labelStyle: TextStyle(
                        color: colorController.textColor.value
                            .withValues(alpha: 0.7)),
                    hintStyle: TextStyle(
                        color: colorController.textColor.value
                            .withValues(alpha: 0.5)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: colorController.textColor.value
                              .withValues(alpha: 0.3)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: colorController.primaryColor.value),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: colorController.primaryColor.value,
                              onPrimary: Colors.white,
                              surface: colorController.backgroundColor.value,
                              onSurface: colorController.textColor.value,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 20, color: colorController.primaryColor.value),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('MMM d, yyyy').format(selectedDate),
                        style: TextStyle(
                          fontSize: 16,
                          color: colorController.textColor.value,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel,
                    style: TextStyle(color: colorController.textColor.value)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.isNotEmpty) {
                    Get.find<PlaylistController>()
                        .createPlaylist(titleController.text, selectedDate);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorController.primaryColor.value,
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.create),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, Playlist playlist) {
    final ColorController colorController = Get.find();
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorController.backgroundColor.value,
        title: Text(
          l10n.deletePlaylist,
          style: TextStyle(color: colorController.textColor.value),
        ),
        content: Text(
          l10n.confirmDeletePlaylist(playlist.title),
          style: TextStyle(color: colorController.textColor.value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel,
                style: TextStyle(color: colorController.textColor.value)),
          ),
          TextButton(
            onPressed: () {
              Get.find<PlaylistController>().deletePlaylist(playlist.id);
              Navigator.pop(context);
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
