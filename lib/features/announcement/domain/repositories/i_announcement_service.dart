import 'package:cloud_firestore/cloud_firestore.dart';

abstract class IAnnouncementService {
  Future<void> checkNewAnnouncements();
  Future<void> createAnnouncement(String title, String message, {DateTime? expiresAt});
  Future<void> deleteAnnouncement(String id);
  Future<void> updateAnnouncement(String id, String title, String message, {DateTime? expiresAt});
  Stream<QuerySnapshot> getAnnouncementsStream();
  Future<void> clearSeenAnnouncements();
}