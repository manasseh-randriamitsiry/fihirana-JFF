import 'package:flutter/material.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';

class PlaylistBottomSheet extends StatefulWidget {
  final List<Hymn>? playlist;
  final Hymn? currentHymn;
  final Function(Hymn)? onHymnChange;
  final Function(Hymn)? onDownload;
  final bool Function(Hymn)? isDownloaded;
  final double? Function(Hymn)? getDownloadProgress;

  const PlaylistBottomSheet({
    super.key,
    required this.playlist,
    required this.currentHymn,
    this.onHymnChange,
    this.onDownload,
    this.isDownloaded,
    this.getDownloadProgress,
  });

  @override
  State<PlaylistBottomSheet> createState() => _PlaylistBottomSheetState();
}

class _PlaylistBottomSheetState extends State<PlaylistBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Playlist',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24),
          Expanded(
            child: widget.playlist == null || widget.playlist!.isEmpty
                ? const Center(
                    child: Text(
                      'No hymns in playlist',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    itemCount: widget.playlist!.length,
                    itemBuilder: (context, index) {
                      final hymn = widget.playlist![index];
                      final isCurrent = hymn.id == widget.currentHymn?.id &&
                          !hymn.id.startsWith('recording_');
                      final isDownloaded =
                          widget.isDownloaded?.call(hymn) ?? false;
                      final downloadProgress =
                          widget.getDownloadProgress?.call(hymn);

                      return ListTile(
                        selected: isCurrent,
                        selectedTileColor: Colors.white10,
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isCurrent ? Colors.white : Colors.white10,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: isCurrent
                                ? const Icon(Icons.bar_chart,
                                    color: Colors.black, size: 20)
                                : Text(
                                    hymn.hymnNumber,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        title: Text(
                          hymn.title,
                          style: TextStyle(
                            color: isCurrent ? Colors.white : Colors.white70,
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'Hymn ${hymn.hymnNumber}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (downloadProgress != null)
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  value: downloadProgress,
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            else if (isDownloaded)
                              const Icon(Icons.check_circle,
                                  color: Colors.green, size: 20)
                            else
                              IconButton(
                                icon: const Icon(Icons.download_rounded,
                                    color: Colors.white54),
                                onPressed: () {
                                  widget.onDownload?.call(hymn);
                                  setState(
                                      () {}); // Refresh to show progress if immediate
                                },
                              ),
                          ],
                        ),
                        onTap: () {
                          widget.onHymnChange?.call(hymn);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}