import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:fihirana/features/announcement/domain/entities/announcement.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/shared/widgets/common/app_ui.dart';
import 'package:fihirana/core/design_system/app_scale.dart';

class AnnouncementCardWidget extends StatelessWidget {
  final Announcement announcement;
  final bool isAdmin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// Pins "il y a N jours" to a fixed moment; the card reads the wall clock
  /// when null, so only tests pass one.
  final DateTime? now;

  const AnnouncementCardWidget({
    super.key,
    required this.announcement,
    required this.isAdmin,
    this.onEdit,
    this.onDelete,
    this.now,
  });

  String _relativeTime(DateTime dateTime) {
    final difference = (now ?? DateTime.now()).difference(dateTime);
    if (difference.inDays > 365) {
      final years = difference.inDays ~/ 365;
      return 'il y a $years an${years > 1 ? 's' : ''}';
    }
    if (difference.inDays > 30) {
      final months = difference.inDays ~/ 30;
      return 'il y a $months mois';
    }
    if (difference.inDays > 0) {
      return 'il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    }
    if (difference.inHours > 0) {
      return 'il y a ${difference.inHours} h';
    }
    if (difference.inMinutes > 0) {
      return 'il y a ${difference.inMinutes} min';
    }
    return 'À l’instant';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final expired = announcement.isExpired();

    return AppTapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.campaign_outlined,
                color: colors.primary,
                size: AppScale.iconLg,
              ),
              const SizedBox(width: AppScale.space12),
              Expanded(
                child: Text(
                  announcement.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (isAdmin)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: colors.onSurfaceVariant,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') onEdit?.call();
                    if (value == 'delete') onDelete?.call();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: AppScale.iconMd,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppScale.space12),
                          Text(l10n.edit),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: AppScale.iconMd,
                            color: colors.error,
                          ),
                          const SizedBox(width: AppScale.space12),
                          Text(
                            l10n.delete,
                            style: TextStyle(color: colors.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppScale.space12),
          Text(
            announcement.message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                ),
          ),
          const SizedBox(height: AppScale.space16),
          Wrap(
            spacing: AppScale.space12,
            runSpacing: AppScale.space8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Metadata(
                icon: Icons.access_time_rounded,
                label: _relativeTime(announcement.createdAt),
              ),
              _Metadata(
                icon: Icons.calendar_today_outlined,
                label: DateFormat('dd/MM/yyyy HH:mm')
                    .format(announcement.createdAt),
              ),
            ],
          ),
          if (announcement.expiresAt != null) ...[
            const SizedBox(height: AppScale.space12),
            DecoratedBox(
              decoration: BoxDecoration(
                color:
                    expired ? colors.errorContainer : colors.primaryContainer,
                borderRadius: BorderRadius.circular(AppScale.radiusControl),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppScale.space12,
                  vertical: AppScale.space8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_busy_outlined,
                      size: AppScale.iconSm,
                      color: expired
                          ? colors.onErrorContainer
                          : colors.onPrimaryContainer,
                    ),
                    const SizedBox(width: AppScale.space8),
                    Flexible(
                      child: Text(
                        'Expire le ${DateFormat('dd/MM/yyyy').format(announcement.expiresAt!)}',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: expired
                                  ? colors.onErrorContainer
                                  : colors.onPrimaryContainer,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Metadata extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Metadata({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppScale.iconSm, color: color),
        const SizedBox(width: AppScale.space4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

class AnnouncementEmptyStateWidget extends StatelessWidget {
  const AnnouncementEmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppEmptyState(
      icon: Icons.notifications_none_rounded,
      title: 'Aucune annonce',
      message: 'Revenez plus tard pour les nouveautés.',
    );
  }
}

class AnnouncementErrorWidget extends StatelessWidget {
  final String error;

  const AnnouncementErrorWidget({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.error_outline_rounded,
      title: 'Impossible de charger les annonces',
      message: error,
    );
  }
}
