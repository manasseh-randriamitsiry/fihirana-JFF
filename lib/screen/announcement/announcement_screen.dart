import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/announcement.dart';
import '../../services/announcement_service.dart';
import '../../controller/color_controller.dart';

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
  DateTime? _selectedExpirationDate; // New field for expiration date

  bool isAdmin() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email == 'manassehrandriamitsiry@gmail.com';
  }

  void _showCreateAnnouncementDialog() {
    _titleController.clear();
    _messageController.clear();
    _selectedExpirationDate = null; // Reset expiration date

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorController.backgroundColor.value,
        title: Text(
          'Hamorona filazana',
          style: TextStyle(color: colorController.textColor.value),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Lohateny',
                labelStyle: TextStyle(color: colorController.textColor.value),
              ),
              style: TextStyle(color: colorController.textColor.value),
            ),
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: 'Hafatra',
                labelStyle: TextStyle(color: colorController.textColor.value),
              ),
              style: TextStyle(color: colorController.textColor.value),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            // Expiration date picker
            ListTile(
              title: Text(
                'Daty farany isehoany',
                style: TextStyle(color: colorController.textColor.value),
              ),
              subtitle: Text(
                _selectedExpirationDate != null
                    ? DateFormat('dd/MM/yyyy').format(_selectedExpirationDate!)
                    : 'Tsy misy daty',
                style: TextStyle(color: colorController.textColor.value.withOpacity(0.7)),
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
              'Hiala',
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
              'Hamorona',
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
    _selectedExpirationDate = announcement.expiresAt; // Set existing expiration date

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorController.backgroundColor.value,
        title: Text(
          'Hanova filazana',
          style: TextStyle(color: colorController.textColor.value),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Lohateny',
                labelStyle: TextStyle(color: colorController.textColor.value),
              ),
              style: TextStyle(color: colorController.textColor.value),
            ),
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: 'Hafatra',
                labelStyle: TextStyle(color: colorController.textColor.value),
              ),
              style: TextStyle(color: colorController.textColor.value),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            // Expiration date picker
            ListTile(
              title: Text(
                'Daty faran\'izay',
                style: TextStyle(color: colorController.textColor.value),
              ),
              subtitle: Text(
                _selectedExpirationDate != null
                    ? DateFormat('dd/MM/yyyy').format(_selectedExpirationDate!)
                    : 'Tsy misy daty faran\'izay',
                style: TextStyle(color: colorController.textColor.value.withOpacity(0.7)),
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
              'Hiala',
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
              'Hanova',
              style: TextStyle(color: colorController.textColor.value),
            ),
          ),
        ],
      ),
    );
  }

  // Method to select expiration date
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

          // Filter out expired announcements
          final announcements = snapshot.data?.docs
              .map((doc) => Announcement.fromFirestore(doc))
              .where((announcement) => announcement.isActive())
              .toList() ?? [];

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
                      // Show expiration date if set
                      if (announcement.expiresAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Mifarana ny: ${DateFormat('dd/MM/yyyy').format(announcement.expiresAt!)}',
                          style: TextStyle(
                            color: announcement.isExpired() 
                                ? Colors.red 
                                : colorController.textColor.value.withOpacity(0.7),
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