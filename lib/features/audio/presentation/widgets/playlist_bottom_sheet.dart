import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/core/design_system/app_scale.dart';
import 'package:fihirana/core/design_system/app_surfaces.dart';
import 'package:fihirana/core/design_system/components/app_register_row.dart';
import 'package:fihirana/core/design_system/components/app_sheet.dart';
import 'package:fihirana/core/design_system/components/app_state_view.dart';
import 'package:fihirana/features/audio/data/services/audio_service.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/l10n/app_localizations.dart';

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
  final AudioService _audioService = AudioService.instance;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final AppSurfaces s = AppSurfaces.of(context);
    final playlist = widget.playlist ?? const <Hymn>[];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppScale.gutter, AppScale.space12,
              AppScale.space12, AppScale.space8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.playlists,
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: const Icon(Icons.close_rounded, size: AppScale.iconLg),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const AppRule(firm: true),
        Obx(() {
          final cue = _audioService.cueRx;
          if (cue.isEmpty) return const SizedBox.shrink();

          return Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppScale.gutter,
                      AppScale.space12, AppScale.space12, AppScale.space4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.next,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: _audioService.clearCue,
                        child: Text(l10n.clear),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    key: const PageStorageKey('playlist_bottom_sheet_cue'),
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(AppScale.gutter,
                        AppScale.space4, AppScale.gutter, AppScale.space8),
                    itemCount: cue.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppScale.space4),
                    itemBuilder: (context, index) {
                      final hymn = cue[index];
                      return AppRegisterRow(
                        key: ValueKey('cue_${hymn.id}_$index'),
                        figure: hymn.hymnNumber,
                        title: hymn.title,
                        // Tap plays it now, which also takes it out of the cue.
                        onTap: () {
                          _audioService.removeCuedAt(index);
                          widget.onHymnChange?.call(hymn);
                          Navigator.pop(context);
                        },
                        trailing: IconButton(
                          tooltip: l10n.remove,
                          icon: const Icon(Icons.close_rounded,
                              size: AppScale.iconMd),
                          onPressed: () => _audioService.removeCuedAt(index),
                        ),
                      );
                    },
                  ),
                ),
                const AppRule(firm: true),
              ],
            ),
          );
        }),
        Flexible(
          child: playlist.isEmpty
              ? AppNotice(
                  title: l10n.noHymns,
                  action: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.close),
                  ),
                )
              : ListView.separated(
                  key: const PageStorageKey('playlist_bottom_sheet_list'),
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(AppScale.gutter,
                      AppScale.space8, AppScale.gutter, AppScale.space12),
                  itemCount: playlist.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppScale.buttonGap),
                  itemBuilder: (context, index) {
                    final hymn = playlist[index];
                    final isCurrent = hymn.id == widget.currentHymn?.id &&
                        !hymn.id.startsWith('recording_');
                    final isDownloaded =
                        widget.isDownloaded?.call(hymn) ?? false;
                    final downloadProgress =
                        widget.getDownloadProgress?.call(hymn);

                    return AppRegisterRow(
                      key: ValueKey(hymn.id),
                      figure: hymn.hymnNumber,
                      title: hymn.title,
                      selected: isCurrent,
                      onTap: () {
                        widget.onHymnChange?.call(hymn);
                        Navigator.pop(context);
                      },
                      trailing: downloadProgress != null
                          ? SizedBox(
                              width: AppScale.iconLg,
                              height: AppScale.iconLg,
                              child: CircularProgressIndicator(
                                value: downloadProgress,
                                strokeWidth: 2,
                              ),
                            )
                          : isDownloaded
                              ? Icon(Icons.check_circle_rounded,
                                  size: AppScale.iconMd, color: s.accent)
                              : IconButton(
                                  tooltip: l10n.download,
                                  icon: const Icon(Icons.download_rounded,
                                      size: AppScale.iconMd),
                                  onPressed: () {
                                    widget.onDownload?.call(hymn);
                                    setState(() {});
                                  },
                                ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
