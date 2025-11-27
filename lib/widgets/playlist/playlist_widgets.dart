import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controller/color_controller.dart';
import '../../controller/playlist_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/playlist.dart';
import '../../screen/playlist/playlist_detail_screen.dart';

class PlaylistItemWidget extends StatelessWidget {
  final Playlist playlist;
  final ColorController colorController;
  final VoidCallback onDelete;

  const PlaylistItemWidget({
    super.key,
    required this.playlist,
    required this.colorController,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
              onDelete();
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
}

class CreatePlaylistDialogWidget extends StatefulWidget {
  const CreatePlaylistDialogWidget({super.key});

  @override
  State<CreatePlaylistDialogWidget> createState() => _CreatePlaylistDialogWidgetState();
}

class _CreatePlaylistDialogWidgetState extends State<CreatePlaylistDialogWidget> {
  final titleController = TextEditingController();
  DateTime selectedDate = DateTime.now();

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    final l10n = AppLocalizations.of(context)!;

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
  }
}

class DeletePlaylistDialogWidget extends StatelessWidget {
  final Playlist playlist;

  const DeletePlaylistDialogWidget({
    super.key,
    required this.playlist,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    final l10n = AppLocalizations.of(context)!;
    
    return AlertDialog(
      backgroundColor: colorController.backgroundColor.value,
      title: Text(
        l10n.deletePlaylist,
        style: TextStyle(color: colorController.textColor.value),
      ),
      content: Text(
        'Are you sure you want to delete playlist "${playlist.title}"?',
        style: TextStyle(color: colorController.textColor.value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel,
              style: TextStyle(color: colorController.textColor.value)),
        ),
        ElevatedButton(
          onPressed: () {
            Get.find<PlaylistController>().deletePlaylist(playlist.id);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text(l10n.delete),
        ),
      ],
    );
  }
}