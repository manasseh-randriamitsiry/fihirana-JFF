import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controller/color_controller.dart';
import '../../controller/playlist_controller.dart';
import '../../services/hymn_service.dart';
import '../../models/hymn.dart';
import '../hymn/hymn_detail_screen.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context) {
    final ColorController colorController = Get.find();
    final PlaylistController playlistController = Get.find();
    final HymnService hymnService = Get.find();

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
              title: const Text('Playlist not found'),
              backgroundColor: colorController.backgroundColor.value,
            ),
            body: const Center(child: Text('Playlist not found')),
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
              Container(
                padding: const EdgeInsets.all(16),
                color:
                    colorController.primaryColor.value.withValues(alpha: 0.05),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 16, color: colorController.primaryColor.value),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: playlist.date,
                          firstDate: DateTime(2000),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: colorController.primaryColor.value,
                                  onPrimary: Colors.white,
                                  surface:
                                      colorController.backgroundColor.value,
                                  onSurface: colorController.textColor.value,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          playlistController.updatePlaylistDate(
                              playlist.id, picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        child: Row(
                          children: [
                            Text(
                              DateFormat('EEEE, MMMM d, yyyy')
                                  .format(playlist.date),
                              style: TextStyle(
                                color: colorController.textColor.value,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                                decorationStyle: TextDecorationStyle.dotted,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit,
                              size: 14,
                              color: colorController.textColor.value
                                  .withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${playlist.hymnIds.length} hymns',
                      style: TextStyle(
                        color: colorController.textColor.value
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // Hymn List
              Expanded(
                child: playlist.hymnIds.isEmpty
                    ? Center(
                        child: Text(
                          'No hymns added yet',
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
                            return const Center(
                              child: Text(
                                'Error loading hymns',
                                style: TextStyle(color: Colors.red),
                              ),
                            );
                          }

                          final hymns = snapshot.data ?? [];

                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: hymns.length,
                            itemBuilder: (context, index) {
                              final hymn = hymns[index];
                              return Card(
                                color: colorController.backgroundColor.value,
                                elevation: 2,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: colorController.textColor.value
                                        .withValues(alpha: 0.1),
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  onTap: () {
                                    Get.to(() =>
                                        HymnDetailScreen(hymnId: hymn.id));
                                  },
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        colorController.primaryColor.value,
                                    child: Text(
                                      hymn.number.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    hymn.title,
                                    style: TextStyle(
                                      color: colorController.textColor.value,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon:
                                        const Icon(Icons.remove_circle_outline),
                                    color: Colors.red.withValues(alpha: 0.7),
                                    onPressed: () {
                                      playlistController.removeHymnFromPlaylist(
                                          playlist.id, hymn.id);
                                    },
                                  ),
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
      }),
    );
  }
}
