import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/announcement.dart';
import 'package:fihirana/services/features/announcement_service.dart';
import '../../controller/color_controller.dart';
import '../../controller/shell_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/context_aware_fab.dart';
import '../../widgets/announcement/announcement_widgets.dart';
import '../../widgets/announcement/announcement_form_widget.dart';

class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  final AnnouncementService _announcementService = AnnouncementService();
  final ColorController colorController = Get.find<ColorController>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  DateTime? _selectedExpirationDate;

  bool isAdmin() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email == 'manassehrandriamitsiry@gmail.com';
  }

  void _showCreateAnnouncementDialog() {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AnnouncementFormWidget(
        title: l10n.createAnnouncement,
        submitButtonText: l10n.create,
        onSubmit: () {
          _announcementService.createAnnouncement(
            _titleController.text,
            _messageController.text,
            expiresAt: _selectedExpirationDate,
          );
          _titleController.clear();
          _messageController.clear();
          _selectedExpirationDate = null;
        },
      ),
    );
  }

  void _showEditAnnouncementDialog(Announcement announcement) {
    _titleController.text = announcement.title;
    _messageController.text = announcement.message;
    _selectedExpirationDate = announcement.expiresAt;
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AnnouncementFormWidget(
        title: l10n.editAnnouncement,
        submitButtonText: l10n.update,
        initialTitle: announcement.title,
        initialMessage: announcement.message,
        initialExpirationDate: announcement.expiresAt,
        onSubmit: () {
          _announcementService.updateAnnouncement(
            announcement.id,
            _titleController.text,
            _messageController.text,
            expiresAt: _selectedExpirationDate,
          );
          _titleController.clear();
          _messageController.clear();
          _selectedExpirationDate = null;
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _resetSeenAnnouncements() async {
    await _announcementService.clearSeenAnnouncements();
    await _announcementService.checkNewAnnouncements();
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
      floatingActionButton: isAdmin()
          ? ContextAwareFAB(
              onAddAnnouncement: _showCreateAnnouncementDialog,
              onRefreshAnnouncements: _resetSeenAnnouncements,
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        color: colorController.primaryColor.value,
        child: StreamBuilder<QuerySnapshot>(
          stream: _announcementService.getAnnouncementsStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return AnnouncementErrorWidget(error: '${snapshot.error}');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: colorController.primaryColor.value,
                ),
              );
            }

            final announcements = snapshot.data?.docs
                    .map((doc) => Announcement.fromFirestore(doc))
                    .where((announcement) => announcement.isActive())
                    .toList() ??
                [];

            if (announcements.isEmpty) {
              return const AnnouncementEmptyStateWidget();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: announcements.length,
              itemBuilder: (context, index) {
                final announcement = announcements[index];
                return AnnouncementCardWidget(
                  announcement: announcement,
                  isAdmin: isAdmin(),
                  onEdit: () => _showEditAnnouncementDialog(announcement),
                  onDelete: () =>
                      _announcementService.deleteAnnouncement(announcement.id),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
