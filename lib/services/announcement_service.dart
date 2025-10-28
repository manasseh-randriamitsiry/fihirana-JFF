import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/announcement.dart';
import '../utility/snackbar_utility.dart';

class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _lastSeenKey = 'last_seen_announcements';

  Future<Set<String>> _getSeenAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    return Set<String>.from(prefs.getStringList(_lastSeenKey) ?? []);
  }

  Future<void> _markAnnouncementAsSeen(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = await _getSeenAnnouncements();
    seen.add(id);
    await prefs.setStringList(_lastSeenKey, seen.toList());
  }

  Future<void> checkNewAnnouncements() async {
    try {
      print('Checking for new announcements...');
      
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt('last_announcement_check') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      if (now - lastCheck < 60000) {
        print('Skipping check - too soon since last check');
        return;
      }
      
      await prefs.setInt('last_announcement_check', now);
      
      final seenAnnouncements = await _getSeenAnnouncements();
      
      final querySnapshot = await _firestore
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .get();

      print('Found ${querySnapshot.docs.length} announcements');

      for (var doc in querySnapshot.docs) {
        final id = doc.id;
        if (!seenAnnouncements.contains(id)) {
          print('New announcement found: $id');
          final data = doc.data();
          
          // Check if announcement has expired
          final expiresAt = data['expiresAt'] as Timestamp?;
          if (expiresAt != null) {
            final expirationDate = expiresAt.toDate();
            if (DateTime.now().isAfter(expirationDate)) {
              print('Skipping expired announcement: $id');
              // Mark expired announcements as seen so they don't show up again
              await _markAnnouncementAsSeen(id);
              continue;
            }
          }
          
          final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
          
          final created = await AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: notificationId,
              channelKey: 'announcement_channel',
              title: 'Filazana vaovao: ${data['title']}',
              body: data['message'],
              notificationLayout: NotificationLayout.BigText,
              payload: {'announcementId': id},
              category: NotificationCategory.Message,
            ),
            actionButtons: [
              NotificationActionButton(
                key: 'OPEN',
                label: 'Hijery',
                actionType: ActionType.Default,
              ),
            ],
          );

          if (created) {
            await _markAnnouncementAsSeen(id);
          }
        }
      }
    } catch (e) {
      print('Error checking announcements: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> createAnnouncement(String title, String message, {DateTime? expiresAt}) async {
    try {
      final user = _auth.currentUser;
      if (user?.email != 'manassehrandriamitsiry@gmail.com') {
        SnackbarUtility.showError(
          title: 'Tsy manana alalana',
          message: 'Tsy afaka mamorona filazana ianao',
        );
        return;
      }

      final announcement = Announcement(
        id: '',
        title: title,
        message: message,
        createdAt: DateTime.now(),
        expiresAt: expiresAt, // Add expiration date
        createdBy: user?.displayName ?? 'Admin',
        createdByEmail: user?.email ?? '',
      );

      await _firestore.collection('announcements').add(announcement.toFirestore());
      
      SnackbarUtility.showSuccess(
        title: 'Fahombiazana',
        message: 'Voaforona ny filazana',
      );
    } catch (e) {
      print('Error creating announcement: $e');
      SnackbarUtility.showError(
        title: 'Nisy olana',
        message: 'Tsy afaka mamorona filazana: $e',
      );
    }
  }

  Future<void> deleteAnnouncement(String id) async {
    try {
      await _firestore.collection('announcements').doc(id).delete();
      SnackbarUtility.showSuccess(
        title: 'Fahombiazana',
        message: 'Voafafa ny filazana',
      );
    } catch (e) {
      SnackbarUtility.showError(
        title: 'Nisy olana',
        message: 'Tsy afaka mamafa ny filazana: $e',
      );
    }
  }

  Future<void> updateAnnouncement(String id, String title, String message, {DateTime? expiresAt}) async {
    try {
      final user = _auth.currentUser;
      if (user?.email != 'manassehrandriamitsiry@gmail.com') {
        SnackbarUtility.showError(
          title: 'Tsy manana alalana',
          message: 'Tsy afaka manova filazana ianao',
        );
        return;
      }

      await _firestore.collection('announcements').doc(id).update({
        'title': title,
        'message': message,
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      SnackbarUtility.showSuccess(
        title: 'Fahombiazana',
        message: 'Voaova ny filazana',
      );
    } catch (e) {
      SnackbarUtility.showError(
        title: 'Nisy olana',
        message: 'Tsy afaka manova ny filazana: $e',
      );
    }
  }

  Stream<QuerySnapshot> getAnnouncementsStream() {
    return _firestore
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> clearSeenAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSeenKey);
    print('Cleared seen announcements');
  }
}