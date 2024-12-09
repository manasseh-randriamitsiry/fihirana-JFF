import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import '../models/announcement.dart';
import '../utility/snackbar_utility.dart';

class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createAnnouncement(String title, String message) async {
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
        createdBy: user?.displayName ?? 'Admin',
        createdByEmail: user?.email ?? '',
      );

      // Add to Firestore first
      final docRef = await _firestore.collection('announcements').add(announcement.toFirestore());

      // Send push notification to all users
      bool notificationResult = await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'announcement_channel',
          title: 'Filazana vaovao: $title',
          body: message,
          notificationLayout: NotificationLayout.BigText,
          payload: {'announcementId': docRef.id},
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'OPEN',
            label: 'Hijery',
            actionType: ActionType.Default,
          ),
        ],
      );

      if (!notificationResult) {
        print('Failed to send notification');
      }

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

  Future<void> updateAnnouncement(String id, String title, String message) async {
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
} 