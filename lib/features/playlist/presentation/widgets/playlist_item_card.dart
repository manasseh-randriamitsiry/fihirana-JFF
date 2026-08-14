import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:fihirana/features/playlist/domain/entities/playlist.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/shared/widgets/common/app_ui.dart';

class PlaylistItemCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const PlaylistItemCard({
    super.key,
    required this.playlist,
    required this.onTap,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat.yMMMd(locale);

    return AppGroupedSurface(
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.queue_music_rounded,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlist.title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: colors.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(playlist.date),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.hymnsCount(playlist.hymnIds.length),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<_PlaylistAction>(
                    tooltip: MaterialLocalizations.of(context).showMenuTooltip,
                    icon: Icon(
                      Icons.more_horiz_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                    onSelected: (action) {
                      if (action == _PlaylistAction.share) {
                        onShare();
                      } else {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: _PlaylistAction.share,
                        child: _PlaylistMenuItem(
                          icon: Icons.share_outlined,
                          label: l10n.share,
                        ),
                      ),
                      PopupMenuItem(
                        value: _PlaylistAction.delete,
                        child: _PlaylistMenuItem(
                          icon: Icons.delete_outline_rounded,
                          label: l10n.delete,
                          color: colors.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum _PlaylistAction { share, delete }

class _PlaylistMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _PlaylistMenuItem({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, size: 20, color: foreground),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: foreground)),
      ],
    );
  }
}
