import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../models/announcement.dart';
import '../../controller/color_controller.dart';
import '../../l10n/app_localizations.dart';

class AnnouncementCardWidget extends StatelessWidget {
  final Announcement announcement;
  final bool isAdmin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AnnouncementCardWidget({
    super.key,
    required this.announcement,
    required this.isAdmin,
    this.onEdit,
    this.onDelete,
  });

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? '1 year ago' : '$years years ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else if (difference.inDays > 0) {
      return difference.inDays == 1
          ? 'Yesterday'
          : '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return difference.inHours == 1
          ? '1 hour ago'
          : '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1
          ? '1 minute ago'
          : '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorController.primaryColor.value.withValues(alpha: 0.15),
            colorController.primaryColor.value.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorController.primaryColor.value.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Could expand to show full details
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorController.primaryColor.value
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.campaign_rounded,
                        color: colorController.primaryColor.value,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        announcement.title,
                        style: TextStyle(
                          color: colorController.textColor.value,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isAdmin)
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: colorController.iconColor.value,
                        ),
                        color: colorController.backgroundColor.value,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        onSelected: (value) {
                          if (value == 'edit' && onEdit != null) {
                            onEdit!();
                          } else if (value == 'delete' && onDelete != null) {
                            onDelete!();
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit,
                                    size: 20,
                                    color: colorController.iconColor.value),
                                const SizedBox(width: 12),
                                Text(l10n.edit,
                                    style: TextStyle(
                                        color:
                                            colorController.textColor.value)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete,
                                    size: 20, color: Colors.red),
                                const SizedBox(width: 12),
                                Text(l10n.delete,
                                    style: TextStyle(
                                        color:
                                            colorController.textColor.value)),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  announcement.message,
                  style: TextStyle(
                    color:
                        colorController.textColor.value.withValues(alpha: 0.9),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: colorController.textColor.value
                          .withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getRelativeTime(announcement.createdAt),
                      style: TextStyle(
                        color: colorController.textColor.value
                            .withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(
                        color: colorController.textColor.value
                            .withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm')
                          .format(announcement.createdAt),
                      style: TextStyle(
                        color: colorController.textColor.value
                            .withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (announcement.expiresAt != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: announcement.isExpired()
                          ? Colors.red.withValues(alpha: 0.1)
                          : colorController.primaryColor.value
                              .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_busy_rounded,
                          size: 14,
                          color: announcement.isExpired()
                              ? Colors.red
                              : colorController.primaryColor.value,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Mifarana ny: ${DateFormat('dd/MM/yyyy').format(announcement.expiresAt!)}',
                          style: TextStyle(
                            color: announcement.isExpired()
                                ? Colors.red
                                : colorController.textColor.value
                                    .withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AnnouncementEmptyStateWidget extends StatelessWidget {
  const AnnouncementEmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 80,
            color: colorController.textColor.value
                .withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Tsy misy filazana',
            style: TextStyle(
              color: colorController.textColor.value,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hiverina rehefa misy vaovao',
            style: TextStyle(
              color: colorController.textColor.value
                  .withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
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
    final colorController = Get.find<ColorController>();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline,
              size: 64, color: Colors.red.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Nisy hadisoana',
            style: TextStyle(
              color: colorController.textColor.value,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: colorController.textColor.value
                  .withValues(alpha: 0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}