import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fihirana/features/announcement/domain/entities/announcement.dart';
import 'package:fihirana/features/announcement/domain/repositories/announcement_repository.dart';
import 'package:fihirana/shared/widgets/common/announcement_notification.dart';

/// Announcement repository implementation
class AnnouncementRepositoryImpl implements AnnouncementRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _lastSeenKey = 'last_seen_announcements';

  @override
  Future<void> createAnnouncement({
    required String title,
    required String message,
    DateTime? expiresAt,
    required String createdBy,
    required String createdByEmail,
  }) async {
    final announcement = Announcement(
      id: '',
      title: title,
      message: message,
      createdAt: DateTime.now(),
      expiresAt: expiresAt,
      createdBy: createdBy,
      createdByEmail: createdByEmail,
    );

    await _firestore
        .collection('announcements')
        .add(announcement.toFirestore());
  }

  @override
  Future<void> updateAnnouncement({
    required String id,
    required String title,
    required String message,
    DateTime? expiresAt,
  }) async {
    await _firestore.collection('announcements').doc(id).update({
      'title': title,
      'message': message,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteAnnouncement(String id) async {
    await _firestore.collection('announcements').doc(id).delete();
  }

  @override
  Future<List<Announcement>> getAllAnnouncements() async {
    final querySnapshot = await _firestore
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => Announcement.tryFromFirestore(doc))
        .whereType<Announcement>()
        .toList();
  }

  @override
  Future<List<Announcement>> getActiveAnnouncements() async {
    final allAnnouncements = await getAllAnnouncements();
    return allAnnouncements
        .where((announcement) => announcement.isActive())
        .toList();
  }

  @override
  Stream<List<Announcement>> streamAllAnnouncements() {
    return _firestore
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Announcement.tryFromFirestore(doc))
            .whereType<Announcement>()
            .toList());
  }

  @override
  Stream<List<Announcement>> streamActiveAnnouncements() {
    return streamAllAnnouncements().map((announcements) => announcements
        .where((announcement) => announcement.isActive())
        .toList());
  }

  @override
  Future<Announcement?> getAnnouncementById(String id) async {
    final doc = await _firestore.collection('announcements').doc(id).get();
    if (!doc.exists) return null;
    return Announcement.tryFromFirestore(doc);
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

      final seenAnnouncements = await getSeenAnnouncements();

      final querySnapshot = await _firestore
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .get();

      for (var doc in querySnapshot.docs) {
        final id = doc.id;
        if (seenAnnouncements.contains(id)) continue;

        // The same parse the list uses: a row the console wrote without a title
        // costs one row. Read straight from the map it would throw, and because
        // the newest announcement comes first that would silence every
        // notification from then on.
        final announcement = Announcement.tryFromFirestore(doc);
        if (announcement == null || !announcement.isActive()) {
          await markAnnouncementAsSeen(id);
          continue;
        }

        await AnnouncementNotificationBuilder.showNewAnnouncement(
          id: id,
          title: announcement.title,
          message: announcement.message,
        );

        await markAnnouncementAsSeen(id);
      }

      // Only a pass that reached the end owns the window, so a query that
      // failed is retried on the next tick instead of waiting another minute.
      await prefs.setInt('last_announcement_check', now);
    } catch (e) {
      // Silently handle errors for notification checking
      return;
    }
  }

  @override
  Future<void> markAnnouncementAsSeen(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = await getSeenAnnouncements();
    seen.add(id);
    await prefs.setStringList(_lastSeenKey, seen.toList());
  }

  @override
  Future<Set<String>> getSeenAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    return Set<String>.from(prefs.getStringList(_lastSeenKey) ?? []);
  }

  @override
  Future<void> clearSeenAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSeenKey);
    // Dropping the list is only useful if the announcements come back, and the
    // check refuses to run inside its own minute window.
    await prefs.remove('last_announcement_check');
  }

  @override
  Future<List<Announcement>> searchAnnouncements(String query) async {
    final allAnnouncements = await getAllAnnouncements();
    final lowerQuery = query.toLowerCase();

    return allAnnouncements
        .where((announcement) =>
            announcement.title.toLowerCase().contains(lowerQuery) ||
            announcement.message.toLowerCase().contains(lowerQuery))
        .toList();
  }

  @override
  Future<int> getAnnouncementsCount() async {
    final snapshot = await _firestore.collection('announcements').get();
    return snapshot.size;
  }

  @override
  Future<int> getActiveAnnouncementsCount() async {
    final activeAnnouncements = await getActiveAnnouncements();
    return activeAnnouncements.length;
  }
}
