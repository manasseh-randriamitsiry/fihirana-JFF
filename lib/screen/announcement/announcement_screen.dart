import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/announcement.dart';
import '../../services/announcement_service.dart';
import '../../controller/color_controller.dart';
import '../../controller/color_controller.dart';

class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen({Key? key}) : super(key: key);

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  final AnnouncementService _announcementService = AnnouncementService();
  final ColorController colorController = Get.find<ColorController>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  bool isAdmin() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email == 'manassehrandriamitsiry@gmail.com';
  }

  void _showCreateAnnouncementDialog() {
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
              );
              _titleController.clear();
              _messageController.clear();
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
              );
              _titleController.clear();
              _messageController.clear();
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
      floatingActionButton: isAdmin()
          ? FloatingActionButton(
              backgroundColor: colorController.primaryColor.value,
              onPressed: _showCreateAnnouncementDialog,
              child: Icon(
                Icons.add,
                color: colorController.iconColor.value,
              ),
            )
          : null,
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

          final announcements = snapshot.data?.docs ?? [];

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
              final announcement =
                  Announcement.fromFirestore(announcements[index]);
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
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm')
                            .format(announcement.createdAt),
                        style: TextStyle(
                          color:
                              colorController.textColor.value.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
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
