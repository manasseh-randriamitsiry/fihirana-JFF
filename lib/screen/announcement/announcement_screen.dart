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

  void _showCreateAnnouncementDialog() {
    _titleController.clear();
    _messageController.clear();
    _selectedExpirationDate = null;
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l10n.title,
                  labelStyle: TextStyle(color: colorController.textColor.value),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color:
                            colorController.textColor.value.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: colorController.primaryColor.value, width: 2),
                  ),
                ),
                style: TextStyle(color: colorController.textColor.value),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: l10n.message,
                  labelStyle: TextStyle(color: colorController.textColor.value),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color:
                            colorController.textColor.value.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: colorController.primaryColor.value, width: 2),
                  ),
                ),
                style: TextStyle(color: colorController.textColor.value),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectExpirationDate(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color:
                            colorController.textColor.value.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                          color: colorController.iconColor.value, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.expirationDate,
                              style: TextStyle(
                                color: colorController.textColor.value
                                    .withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedExpirationDate != null
                                  ? DateFormat('dd/MM/yyyy')
                                      .format(_selectedExpirationDate!)
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
            child: Text(l10n.cancel2,
                style: TextStyle(color: colorController.textColor.value)),
          ),
          ElevatedButton(
            onPressed: () {
              if (_titleController.text.trim().isEmpty ||
                  _messageController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields')),
                );
                return;
              }
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
            style: ElevatedButton.styleFrom(
              backgroundColor: colorController.primaryColor.value,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(l10n.create),
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
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l10n.title,
                  labelStyle: TextStyle(color: colorController.textColor.value),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color:
                            colorController.textColor.value.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: colorController.primaryColor.value, width: 2),
                  ),
                ),
                style: TextStyle(color: colorController.textColor.value),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: l10n.message,
                  labelStyle: TextStyle(color: colorController.textColor.value),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color:
                            colorController.textColor.value.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: colorController.primaryColor.value, width: 2),
                  ),
                ),
                style: TextStyle(color: colorController.textColor.value),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectExpirationDate(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color:
                            colorController.textColor.value.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                          color: colorController.iconColor.value, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.expirationDate,
                              style: TextStyle(
                                color: colorController.textColor.value
                                    .withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedExpirationDate != null
                                  ? DateFormat('dd/MM/yyyy')
                                      .format(_selectedExpirationDate!)
                                  : l10n.noExpirationDate,
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
            child: Text(l10n.cancel2,
                style: TextStyle(color: colorController.textColor.value)),
          ),
          ElevatedButton(
            onPressed: () {
              if (_titleController.text.trim().isEmpty ||
                  _messageController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields')),
                );
                return;
              }
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
            style: ElevatedButton.styleFrom(
              backgroundColor: colorController.primaryColor.value,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(l10n.update),
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
              onPrimary: Colors.white,
              onSurface: colorController.textColor.value,
            ), dialogTheme: DialogThemeData(backgroundColor: colorController.backgroundColor.value),
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
            Icons.arrow_back_ios_new_rounded,
            color: colorController.iconColor.value,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      floatingActionButton: isAdmin()
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'add_announcement',
                  backgroundColor: colorController.primaryColor.value,
                  elevation: 4,
                  onPressed: _showCreateAnnouncementDialog,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'refresh_announcements',
                  backgroundColor:
                      colorController.primaryColor.value.withValues(alpha: 0.8),
                  elevation: 4,
                  onPressed: _resetSeenAnnouncements,
                  child: const Icon(Icons.refresh, color: Colors.white),
                ),
              ],
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
                      '${snapshot.error}',
                      style: TextStyle(
                        color: colorController.textColor.value.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
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
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 80,
                      color: colorController.textColor.value.withValues(alpha: 0.3),
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
                        color: colorController.textColor.value.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: announcements.length,
              itemBuilder: (context, index) {
                final announcement = announcements[index];
                return _buildAnnouncementCard(announcement);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement) {
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
                        color:
                            colorController.primaryColor.value.withValues(alpha: 0.2),
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
                    if (isAdmin())
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: colorController.iconColor.value,
                        ),
                        color: colorController.backgroundColor.value,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditAnnouncementDialog(announcement);
                          } else if (value == 'delete') {
                            _announcementService
                                .deleteAnnouncement(announcement.id);
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
                                Text('Edit',
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
                                Text('Delete',
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
                    color: colorController.textColor.value.withValues(alpha: 0.9),
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
                      color: colorController.textColor.value.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getRelativeTime(announcement.createdAt),
                      style: TextStyle(
                        color: colorController.textColor.value.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(
                        color: colorController.textColor.value.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm')
                          .format(announcement.createdAt),
                      style: TextStyle(
                        color: colorController.textColor.value.withValues(alpha: 0.6),
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
                          : colorController.primaryColor.value.withValues(alpha: 0.1),
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
