import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/announcement.dart';
import '../../services/announcement_service.dart';
import '../../controller/color_controller.dart';
import '../../l10n/app_localizations.dart';

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
    _titleController.clear();
    _messageController.clear();
    _selectedExpirationDate = null;
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorController.backgroundColor.value,
        title: Text(
          l10n.createAnnouncement,
          style: TextStyle(color: colorController.textColor.value),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n.title,
                labelStyle: TextStyle(color: colorController.textColor.value),
              ),
              style: TextStyle(color: colorController.textColor.value),
            ),
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: l10n.message,
                labelStyle: TextStyle(color: colorController.textColor.value),
              ),
              style: TextStyle(color: colorController.textColor.value),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            ListTile(
              title: Text(
                l10n.expirationDate,
                style: TextStyle(color: colorController.textColor.value),
              ),
              subtitle: Text(
                _selectedExpirationDate != null
                    ? DateFormat('dd/MM/yyyy').format(_selectedExpirationDate!)
                    : l10n.noDate,
                style: TextStyle(
                    color: colorController.textColor.value.withOpacity(0.7)),
              ),
              trailing: Icon(
                Icons.calendar_today,
                color: colorController.iconColor.value,
              ),
              onTap: () => _selectExpirationDate(context),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel2,
              style: TextStyle(color: colorController.textColor.value),
            ),
          ),
          TextButton(
            onPressed: () {
              _announcementService.createAnnouncement(
                _titleController.text,
                _messageController.text,
                expiresAt: _selectedExpirationDate,
              );
              _titleController.clear();
              _messageController.clear();
              _selectedExpirationDate = null;
              Navigator.pop(context);
            },
            child: Text(
              l10n.create,
              style: TextStyle(color: colorController.textColor.value),
            ),
          ),
        ],
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
      builder: (context) => AlertDialog(
        backgroundColor: colorController.backgroundColor.value,
        title: Text(
          l10n.editAnnouncement,
          style: TextStyle(color: colorController.textColor.value),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n.title,
                labelStyle: TextStyle(color: colorController.textColor.value),
              ),
              style: TextStyle(color: colorController.textColor.value),
            ),
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: l10n.message,
                labelStyle: TextStyle(color: colorController.textColor.value),
              ),
              style: TextStyle(color: colorController.textColor.value),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            ListTile(
              title: Text(
                l10n.expirationDate,
                style: TextStyle(color: colorController.textColor.value),
              ),
              subtitle: Text(
                _selectedExpirationDate != null
                    ? DateFormat('dd/MM/yyyy').format(_selectedExpirationDate!)
                    : l10n.noExpirationDate,
                style: TextStyle(
                    color: colorController.textColor.value.withOpacity(0.7)),
              ),
              trailing: Icon(
                Icons.calendar_today,
                color: colorController.iconColor.value,
              ),
              onTap: () => _selectExpirationDate(context),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel2,
              style: TextStyle(color: colorController.textColor.value),
            ),
          ),
          TextButton(
            onPressed: () {
              _announcementService.updateAnnouncement(
                announcement.id,
                _titleController.text,
                _messageController.text,
                expiresAt: _selectedExpirationDate,
              );
              _titleController.clear();
              _messageController.clear();
              _selectedExpirationDate = null;
              Navigator.pop(context);
            },
            child: Text(
              l10n.update,
              style: TextStyle(color: colorController.textColor.value),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectExpirationDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpirationDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: colorController.primaryColor.value,
              onPrimary: colorController.textColor.value,
              onSurface: colorController.textColor.value,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: colorController.textColor.value,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedExpirationDate = picked;
      });
    }
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
        title: Text(
          'Filazana',
          style: TextStyle(
            color: colorController.textColor.value,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: colorController.iconColor.value,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isAdmin())
            FloatingActionButton(
              heroTag: 'add_announcement',
              backgroundColor: colorController.primaryColor.value,
              onPressed: _showCreateAnnouncementDialog,
              child: Icon(
                Icons.add,
                color: colorController.iconColor.value,
              ),
            ),
          const SizedBox(height: 10),
          if (isAdmin())
            FloatingActionButton(
              heroTag: 'refresh_announcements',
              backgroundColor: colorController.primaryColor.value,
              onPressed: _resetSeenAnnouncements,
              child: Icon(
                Icons.refresh,
                color: colorController.iconColor.value,
              ),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _announcementService.getAnnouncementsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Nisy hadisoana: ${snapshot.error}',
                style: TextStyle(color: colorController.textColor.value),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final announcements = snapshot.data?.docs
                  .map((doc) => Announcement.fromFirestore(doc))
                  .where((announcement) => announcement.isActive())
                  .toList() ??
              [];

          if (announcements.isEmpty) {
            return Center(
              child: Text(
                'Tsy misy filazana',
                style: TextStyle(color: colorController.textColor.value),
              ),
            );
          }

          return ListView.builder(
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final announcement = announcements[index];
              return Card(
                color: colorController.primaryColor.value.withOpacity(0.5),
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(
                    announcement.title,
                    style: TextStyle(
                      color: colorController.textColor.value,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        announcement.message,
                        style:
                            TextStyle(color: colorController.textColor.value),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm')
                            .format(announcement.createdAt),
                        style: TextStyle(
                          color:
                              colorController.textColor.value.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      if (announcement.expiresAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Mifarana ny: ${DateFormat('dd/MM/yyyy').format(announcement.expiresAt!)}',
                          style: TextStyle(
                            color: announcement.isExpired()
                                ? Colors.red
                                : colorController.textColor.value
                                    .withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: isAdmin()
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.edit,
                                color: colorController.iconColor.value,
                              ),
                              onPressed: () =>
                                  _showEditAnnouncementDialog(announcement),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: colorController.iconColor.value,
                              ),
                              onPressed: () => _announcementService
                                  .deleteAnnouncement(announcement.id),
                            ),
                          ],
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
