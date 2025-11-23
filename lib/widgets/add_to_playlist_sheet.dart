import 'package:fihirana/controller/color_controller.dart';
import 'package:fihirana/controller/playlist_controller.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AddToPlaylistSheet extends StatefulWidget {
  final String hymnId;
  final VoidCallback? onHymnAdded;

  const AddToPlaylistSheet({
    super.key,
    required this.hymnId,
    this.onHymnAdded,
  });

  @override
  State<AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends State<AddToPlaylistSheet> {
  final PlaylistController _playlistController = Get.find();
  final ColorController _colorController = Get.find();
  final TextEditingController _newPlaylistController = TextEditingController();
  final RxBool _isCreating = false.obs;
  final Rx<DateTime> _selectedDate = DateTime.now().obs;

  @override
  void dispose() {
    _newPlaylistController.dispose();
    super.dispose();
  }

  Future<void> _createAndAdd() async {
    final title = _newPlaylistController.text.trim();
    if (title.isEmpty) return;

    final playlistId = await _playlistController.createPlaylist(
      title,
      _selectedDate.value,
    );

    if (playlistId != null) {
      await _playlistController.addHymnToPlaylist(playlistId, widget.hymnId);
      widget.onHymnAdded?.call();
      if (mounted) Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Obx(() {
          final backgroundColor = _colorController.backgroundColor.value;
          final textColor = _colorController.textColor.value;
          final primaryColor = _colorController.primaryColor.value;

          return Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Handle bar
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: textColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add to Playlist',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: textColor),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // Create New Playlist Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          _isCreating.value = !_isCreating.value;
                          if (_isCreating.value) {
                            // Focus text field after a short delay to allow UI to rebuild
                            Future.delayed(const Duration(milliseconds: 100),
                                () {
                              // We can't easily focus here without a FocusNode,
                              // but the user can tap.
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isCreating.value ? Icons.remove : Icons.add,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Create New Playlist',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Inline Creation Form
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        child: _isCreating.value
                            ? Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _newPlaylistController,
                                            style: TextStyle(color: textColor),
                                            decoration: InputDecoration(
                                              hintText: 'Playlist Name',
                                              hintStyle: TextStyle(
                                                color: textColor.withValues(
                                                    alpha: 0.5),
                                              ),
                                              filled: true,
                                              fillColor: textColor.withValues(
                                                  alpha: 0.05),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide.none,
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                            ),
                                            onSubmitted: (_) => _createAndAdd(),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () async {
                                            final picked = await showDatePicker(
                                              context: context,
                                              initialDate: _selectedDate.value,
                                              firstDate: DateTime.now(),
                                              lastDate: DateTime.now().add(
                                                  const Duration(days: 365)),
                                              builder: (context, child) {
                                                return Theme(
                                                  data: Theme.of(context)
                                                      .copyWith(
                                                    colorScheme:
                                                        ColorScheme.light(
                                                      primary: primaryColor,
                                                      onPrimary: Colors.white,
                                                      surface: backgroundColor,
                                                      onSurface: textColor,
                                                    ),
                                                  ),
                                                  child: child!,
                                                );
                                              },
                                            );
                                            if (picked != null) {
                                              _selectedDate.value = picked;
                                            }
                                          },
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: textColor.withValues(
                                                  alpha: 0.05),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Obx(() => Icon(
                                                  Icons.calendar_today,
                                                  color: _selectedDate.value
                                                          .isAfter(DateTime
                                                                  .now()
                                                              .subtract(
                                                                  const Duration(
                                                                      days: 1)))
                                                      ? primaryColor
                                                      : textColor.withValues(
                                                          alpha: 0.5),
                                                )),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Obx(() => Text(
                                              DateFormat('MMM d, yyyy')
                                                  .format(_selectedDate.value),
                                              style: TextStyle(
                                                color: textColor.withValues(
                                                    alpha: 0.7),
                                                fontSize: 14,
                                              ),
                                            )),
                                        const SizedBox(width: 12),
                                        ElevatedButton(
                                          onPressed: _createAndAdd,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryColor,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 12,
                                            ),
                                          ),
                                          child: const Text('Create'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),

                // Existing Playlists List
                Expanded(
                  child: _playlistController.isLoading.value
                      ? Center(
                          child: CircularProgressIndicator(color: primaryColor))
                      : _playlistController.playlists.isEmpty
                          ? Center(
                              child: Text(
                                'No playlists yet',
                                style: TextStyle(
                                  color: textColor.withValues(alpha: 0.5),
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _playlistController.playlists.length,
                              itemBuilder: (context, index) {
                                final playlist =
                                    _playlistController.playlists[index];
                                final isAdded =
                                    playlist.hymnIds.contains(widget.hymnId);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: textColor.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    onTap: () async {
                                      if (!isAdded) {
                                        await _playlistController
                                            .addHymnToPlaylist(
                                          playlist.id,
                                          widget.hymnId,
                                        );
                                        widget.onHymnAdded?.call();
                                        Get.back();
                                      }
                                    },
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isAdded
                                            ? Colors.green
                                                .withValues(alpha: 0.1)
                                            : primaryColor.withValues(
                                                alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isAdded
                                            ? Icons.check
                                            : Icons.queue_music,
                                        color: isAdded
                                            ? Colors.green
                                            : primaryColor,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      playlist.title,
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      DateFormat('MMM d, yyyy')
                                          .format(playlist.date),
                                      style: TextStyle(
                                        color: textColor.withValues(alpha: 0.6),
                                        fontSize: 12,
                                      ),
                                    ),
                                    trailing: isAdded
                                        ? const Text(
                                            'Added',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : Icon(
                                            Icons.add_circle_outline,
                                            color: textColor.withValues(
                                                alpha: 0.3),
                                          ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}
