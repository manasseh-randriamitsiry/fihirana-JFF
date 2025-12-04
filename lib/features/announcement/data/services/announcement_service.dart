import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fihirana/features/announcement/domain/entities/announcement.dart';
import 'package:fihirana/shared/widgets/common/announcement_notification.dart';
import 'package:fihirana/core/utils/snackbar_utility.dart';
import 'package:fihirana/features/announcement/domain/repositories/i_announcement_service.dart';

class AnnouncementService implements IAnnouncementService {
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

  @override
  Future<void> checkNewAnnouncements() async {
    try {

      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt('last_announcement_check') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (now - lastCheck < 60000) {
        return;
      }

      await prefs.setInt('last_announcement_check', now);

      final seenAnnouncements = await _getSeenAnnouncements();

      final querySnapshot = await _firestore
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .get();

      for (var doc in querySnapshot.docs) {
        final id = doc.id;
        if (!seenAnnouncements.contains(id)) {
          final data = doc.data();

          final expiresAt = data['expiresAt'] as Timestamp?;
          if (expiresAt != null) {
            final expirationDate = expiresAt.toDate();
            if (DateTime.now().isAfter(expirationDate)) {

              await _markAnnouncementAsSeen(id);
              continue;
            }
          }

          await AnnouncementNotificationBuilder.showNewAnnouncement(
            id: id,
            title: data['title'],
            message: data['message'],
          );

          await _markAnnouncementAsSeen(id);
        }
      }
    } catch (e) {
      return;
    }
  }

  @override
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
        expiresAt: expiresAt,
        createdBy: user?.displayName ?? 'Admin',
        createdByEmail: user?.email ?? '',
      );

      await _firestore.collection('announcements').add(announcement.toFirestore());

      SnackbarUtility.showSuccess(
        title: 'Fahombiazana',
        message: 'Voaforona ny filazana',
      );
    } catch (e) {
      SnackbarUtility.showError(
        title: 'Nisy olana',
        message: 'Tsy afaka mamorona filazana: $e',
      );
    }
  }

  @override
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

  @override
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

  @override
  Stream<QuerySnapshot> getAnnouncementsStream() {
    return _firestore
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Future<void> clearSeenAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSeenKey);
  }
}