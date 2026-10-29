import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fihirana/core/design_system/app_scale.dart';
import 'package:fihirana/core/design_system/app_surfaces.dart';
import 'package:fihirana/core/design_system/components/app_sheet.dart';
import 'package:fihirana/l10n/app_localizations.dart';

class PlayerControls extends StatelessWidget {
  final bool isPlaying;
  final bool isLoading;
  final bool autoPlayNext;
  final Function(bool)? onAutoPlayNextChange;
  final VoidCallback onPlayPrevious;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onPlayNext;
  final VoidCallback onShowPlaylist;

  const PlayerControls({
    super.key,
    required this.isPlaying,
    required this.isLoading,
    required this.autoPlayNext,
    this.onAutoPlayNextChange,
    required this.onPlayPrevious,
    required this.onTogglePlayPause,
    required this.onPlayNext,
    required this.onShowPlaylist,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final AppSurfaces s = AppSurfaces.of(context);
    final TextTheme type = Theme.of(context).textTheme;

    void tap(VoidCallback action) {
      HapticFeedback.lightImpact();
      action();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              tooltip: l10n.previous,
              onPressed: () => tap(onPlayPrevious),
              icon: const Icon(Icons.skip_previous_rounded,
                  size: AppScale.iconLg),
            ),
            FilledButton(
              onPressed: () => tap(onTogglePlayPause),
              style: FilledButton.styleFrom(
                minimumSize: const Size(72, 72),
                padding: EdgeInsets.zero,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: AppScale.iconLg,
                      height: AppScale.iconLg,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: AppScale.iconLg * 1.5,
                    ),
            ),
            IconButton(
              tooltip: l10n.next,
              onPressed: () => tap(onPlayNext),
              icon: const Icon(Icons.skip_next_rounded, size: AppScale.iconLg),
            ),
          ],
        ),
        const SizedBox(height: AppScale.space8),
        const AppRule(),
        const SizedBox(height: AppScale.space4),
        Row(
          children: [
            SizedBox(
              height: AppScale.hitTarget,
              child: Switch(
                value: autoPlayNext,
                onChanged: onAutoPlayNextChange,
              ),
            ),
            Expanded(
              child: Text(
                l10n.next,
                style: type.bodySmall?.copyWith(color: s.muted),
              ),
            ),
            TextButton.icon(
              onPressed: () => tap(onShowPlaylist),
              icon: const Icon(Icons.playlist_play_rounded,
                  size: AppScale.iconMd),
              label: Text(l10n.playlists,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ],
    );
  }
}
