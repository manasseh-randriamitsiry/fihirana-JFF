import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fihirana/core/navigation/shell_controller.dart';
import 'package:fihirana/core/utils/snackbar_utility.dart';
import 'package:fihirana/features/announcement/domain/entities/announcement.dart';
import 'package:fihirana/features/announcement/presentation/controllers/announcement_controller.dart';
import 'package:fihirana/features/announcement/presentation/widgets/announcement_widgets.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/shared/widgets/navigation/context_aware_fab.dart';

class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  final AnnouncementController _announcementController =
      Get.find<AnnouncementController>();

  Future<void> _showAnnouncementDialog({Announcement? announcement}) async {
    final l10n = AppLocalizations.of(context);
    final titleController = TextEditingController(text: announcement?.title);
    final messageController =
        TextEditingController(text: announcement?.message);
    DateTime? expiresAt = announcement?.expiresAt;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final colors = Theme.of(dialogContext).colorScheme;
          return AlertDialog(
            title: Text(
              announcement == null
                  ? l10n.createAnnouncement
                  : l10n.editAnnouncement,
            ),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(labelText: l10n.title),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: messageController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: InputDecoration(labelText: l10n.message),
                    ),
                    const SizedBox(height: 16),
                    Material(
                      color:
                          colors.surfaceContainerHighest.withValues(alpha: .45),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: dialogContext,
                            initialDate: expiresAt ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            setDialogState(() => expiresAt = date);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Icon(Icons.event_outlined, color: colors.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.expirationDate,
                                      style: Theme.of(dialogContext)
                                          .textTheme
                                          .labelMedium,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      expiresAt == null
                                          ? l10n.noDate
                                          : '${expiresAt!.day.toString().padLeft(2, '0')}/${expiresAt!.month.toString().padLeft(2, '0')}/${expiresAt!.year}',
                                      style: Theme.of(dialogContext)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: colors.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.cancel2),
              ),
              FilledButton(
                onPressed: () {
                  if (titleController.text.trim().isEmpty ||
                      messageController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.fillAllFields)),
                    );
                    return;
                  }
                  Navigator.pop(dialogContext, true);
                },
                child: Text(announcement == null ? l10n.create : l10n.update),
              ),
            ],
          );
        },
      ),
    );

    if (shouldSave == true) {
      final success = announcement == null
          ? await _announcementController.createAnnouncement(
              title: titleController.text.trim(),
              message: messageController.text.trim(),
              expiresAt: expiresAt,
            )
          : await _announcementController.updateAnnouncement(
              id: announcement.id,
              title: titleController.text.trim(),
              message: messageController.text.trim(),
              expiresAt: expiresAt,
            );
      if (success) {
        SnackbarUtility.showSuccess(
          title: 'Terminé',
          message: announcement == null
              ? 'L’annonce a été créée.'
              : 'L’annonce a été mise à jour.',
        );
      } else {
        SnackbarUtility.showError(
          title: 'Une erreur est survenue',
          message: _announcementController.errorMessage.value,
        );
      }
    }
    titleController.dispose();
    messageController.dispose();
  }

  Future<void> _deleteAnnouncement(Announcement announcement) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.delete),
        content: const Text('Voulez-vous supprimer cette annonce ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel2),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final success = await _announcementController.deleteAnnouncement(
      announcement.id,
    );
    if (success) {
      SnackbarUtility.showSuccess(
        title: 'Terminé',
        message: 'L’annonce a été supprimée.',
      );
    } else {
      SnackbarUtility.showError(
        title: 'Une erreur est survenue',
        message: _announcementController.errorMessage.value,
      );
    }
  }

  Future<void> _resetSeenAnnouncements() {
    return _announcementController.clearSeenAnnouncements();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          onPressed: Get.find<ShellController>().toggleDrawer,
          icon: const Icon(Icons.menu_rounded),
        ),
        title: const Text('Annonces'),
      ),
      floatingActionButton: _announcementController.isAdmin
          ? ContextAwareFAB(
              onAddAnnouncement: _showAnnouncementDialog,
              onRefreshAnnouncements: _resetSeenAnnouncements,
            )
          : null,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: colors.primary,
          onRefresh: _announcementController.refresh,
          child: Obx(() {
            if (_announcementController.errorMessage.isNotEmpty) {
              return AnnouncementErrorWidget(
                error: _announcementController.errorMessage.value,
              );
            }
            if (_announcementController.isLoading.value &&
                _announcementController.activeAnnouncements.isEmpty) {
              return Center(
                  child: CircularProgressIndicator(color: colors.primary));
            }

            final announcements = _announcementController.activeAnnouncements;
            if (announcements.isEmpty) {
              return const AnnouncementEmptyStateWidget();
            }
            return ListView.separated(
              key: const PageStorageKey('announcements_list'),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
              itemCount: announcements.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Text(
                    '${announcements.length} annonce${announcements.length > 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  );
                }
                final announcement = announcements[index - 1];
                return AnnouncementCardWidget(
                  key: ValueKey(announcement.id),
                  announcement: announcement,
                  isAdmin: _announcementController.isAdmin,
                  onEdit: () =>
                      _showAnnouncementDialog(announcement: announcement),
                  onDelete: () => _deleteAnnouncement(announcement),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
