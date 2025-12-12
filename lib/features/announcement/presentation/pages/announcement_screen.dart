import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fihirana/features/announcement/domain/entities/announcement.dart';
import 'package:fihirana/features/announcement/presentation/controllers/announcement_controller.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/core/navigation/shell_controller.dart';
import 'package:fihirana/core/utils/snackbar_utility.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/shared/widgets/navigation/context_aware_fab.dart';
import 'package:fihirana/features/announcement/presentation/widgets/announcement_widgets.dart';

class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  final AnnouncementController _announcementController = Get.find<AnnouncementController>();
  final ColorController colorController = Get.find<ColorController>();

void _showCreateAnnouncementDialog() {
    final l10n = AppLocalizations.of(context);
    String title = '';
    String message = '';
    DateTime? expiresAt;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: colorController.backgroundColor.value,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            l10n.createAnnouncement,
            style: TextStyle(
              color: colorController.textColor.value,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: l10n.title,
                    labelStyle: TextStyle(color: colorController.textColor.value),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorController.textColor.value.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorController.primaryColor.value, width: 2),
                    ),
                  ),
                  style: TextStyle(color: colorController.textColor.value),
                  onChanged: (value) => title = value,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: l10n.message,
                    labelStyle: TextStyle(color: colorController.textColor.value),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorController.textColor.value.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorController.primaryColor.value, width: 2),
                    ),
                  ),
                  style: TextStyle(color: colorController.textColor.value),
                  maxLines: 4,
                  onChanged: (value) => message = value,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: expiresAt ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        expiresAt = picked;
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: colorController.textColor.value.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: colorController.iconColor.value, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.expirationDate,
                                style: TextStyle(
                                  color: colorController.textColor.value.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                expiresAt != null
                                    ? '${expiresAt!.day}/${expiresAt!.month}/${expiresAt!.year}'
                                    : l10n.noDate,
                                style: TextStyle(
                                  color: colorController.textColor.value,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel2, style: TextStyle(color: colorController.textColor.value)),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context, rootNavigator: false);
                
                if (title.trim().isEmpty || message.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.fillAllFields)),
                  );
                  return;
                }
                
                final success = await _announcementController.createAnnouncement(
                  title: title,
                  message: message,
                  expiresAt: expiresAt,
                );
                
                if (success) {
                  SnackbarUtility.showSuccess(
                    title: 'Fahombiazana',
                    message: 'Voaforona ny filazana',
                  );
                  navigator.pop();
                } else {
                  SnackbarUtility.showError(
                    title: 'Nisy olana',
                    message: _announcementController.errorMessage.value,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorController.primaryColor.value,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(l10n.create),
            ),
          ],
        ),
      ),
    );
  }

void _showEditAnnouncementDialog(Announcement announcement) {
    String title = announcement.title;
    String message = announcement.message;
    DateTime? expiresAt = announcement.expiresAt;
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: colorController.backgroundColor.value,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            l10n.editAnnouncement,
            style: TextStyle(
              color: colorController.textColor.value,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: l10n.title,
                    labelStyle: TextStyle(color: colorController.textColor.value),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorController.textColor.value.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorController.primaryColor.value, width: 2),
                    ),
                  ),
                  style: TextStyle(color: colorController.textColor.value),
                  controller: TextEditingController(text: title)..selection = TextSelection.fromPosition(TextPosition(offset: title.length)),
                  onChanged: (value) => title = value,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: l10n.message,
                    labelStyle: TextStyle(color: colorController.textColor.value),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorController.textColor.value.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorController.primaryColor.value, width: 2),
                    ),
                  ),
                  style: TextStyle(color: colorController.textColor.value),
                  maxLines: 4,
                  controller: TextEditingController(text: message)..selection = TextSelection.fromPosition(TextPosition(offset: message.length)),
                  onChanged: (value) => message = value,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: expiresAt ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        expiresAt = picked;
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: colorController.textColor.value.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: colorController.iconColor.value, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.expirationDate,
                                style: TextStyle(
                                  color: colorController.textColor.value.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                expiresAt != null
                                    ? '${expiresAt!.day}/${expiresAt!.month}/${expiresAt!.year}'
                                    : l10n.noDate,
                                style: TextStyle(
                                  color: colorController.textColor.value,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel2, style: TextStyle(color: colorController.textColor.value)),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context, rootNavigator: false);
                
                if (title.trim().isEmpty || message.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.fillAllFields)),
                  );
                  return;
                }
                
                final success = await _announcementController.updateAnnouncement(
                  id: announcement.id,
                  title: title,
                  message: message,
                  expiresAt: expiresAt,
                );
                
                if (success) {
                  SnackbarUtility.showSuccess(
                    title: 'Fahombiazana',
                    message: 'Voaova ny filazana',
                  );
                  navigator.pop();
                } else {
                  SnackbarUtility.showError(
                    title: 'Nisy olana',
                    message: _announcementController.errorMessage.value,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorController.primaryColor.value,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(l10n.update),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

Future<void> _resetSeenAnnouncements() async {
    await _announcementController.clearSeenAnnouncements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorController.backgroundColor.value,
      appBar: AppBar(
        backgroundColor: colorController.backgroundColor.value,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Filazana',
          style: TextStyle(
            color: colorController.textColor.value,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.menu_rounded,
            color: colorController.iconColor.value,
          ),
          onPressed: () => Get.find<ShellController>().toggleDrawer(),
        ),
      ),
floatingActionButton: _announcementController.isAdmin
          ? ContextAwareFAB(
              onAddAnnouncement: _showCreateAnnouncementDialog,
              onRefreshAnnouncements: _resetSeenAnnouncements,
            )
          : null,
body: RefreshIndicator(
        onRefresh: () async {
          await _announcementController.refresh();
        },
        color: colorController.primaryColor.value,
        child: Obx(() {
          if (_announcementController.errorMessage.isNotEmpty) {
            return AnnouncementErrorWidget(error: _announcementController.errorMessage.value);
          }

          if (_announcementController.isLoading.value && _announcementController.activeAnnouncements.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                color: colorController.primaryColor.value,
              ),
            );
          }

          final announcements = _announcementController.activeAnnouncements;

          if (announcements.isEmpty) {
            return const AnnouncementEmptyStateWidget();
          }

          return ListView.builder(
            key: const PageStorageKey('announcements_list'),
            padding: const EdgeInsets.all(16),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final announcement = announcements[index];
              return AnnouncementCardWidget(
                key: ValueKey(announcement.id),
                announcement: announcement,
                isAdmin: _announcementController.isAdmin,
                onEdit: () => _showEditAnnouncementDialog(announcement),
                onDelete: () async {
                  final success = await _announcementController.deleteAnnouncement(announcement.id);
                  if (success) {
                    SnackbarUtility.showSuccess(
                      title: 'Fahombiazana',
                      message: 'Voafafa ny filazana',
                    );
                  } else {
                    SnackbarUtility.showError(
                      title: 'Nisy olana',
                      message: _announcementController.errorMessage.value,
                    );
                  }
                },
              );
            },
          );
        }),
      ),
    );
  }
}
