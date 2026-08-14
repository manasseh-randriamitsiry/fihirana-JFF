import 'package:flutter/material.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/shared/widgets/common/app_ui.dart';

class AdminStatTileWidget extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  const AdminStatTileWidget({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              child: Icon(icon, size: 17),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: Theme.of(context).textTheme.labelSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class AdminStatsRowWidget extends StatelessWidget {
  final Map<String, dynamic> stats;

  const AdminStatsRowWidget({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: AppGroupedSurface(
        children: [
          Row(
            children: [
              AdminStatTileWidget(
                title: AppLocalizations.of(context).users,
                value: '${stats['totalUsers']}',
                subtitle: AppLocalizations.of(context)
                    .activeUsersCount(stats['activeUsers']),
                icon: Icons.people_outline_rounded,
                backgroundColor: colors.primaryContainer,
                foregroundColor: colors.onPrimaryContainer,
              ),
              AdminStatTileWidget(
                title: AppLocalizations.of(context).hymns,
                value: '${stats['totalHymns']}',
                subtitle: AppLocalizations.of(context).totalAdded,
                icon: Icons.library_music_outlined,
                backgroundColor: colors.secondaryContainer,
                foregroundColor: colors.onSecondaryContainer,
              ),
              AdminStatTileWidget(
                title: AppLocalizations.of(context).installs,
                value: '${stats['installations']}',
                subtitle: AppLocalizations.of(context).allTime,
                icon: Icons.download_outlined,
                backgroundColor: colors.tertiaryContainer,
                foregroundColor: colors.onTertiaryContainer,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
