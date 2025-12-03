import 'package:fihirana/features/announcement/domain/entities/announcement.dart';

/// Announcement repository interface
abstract class AnnouncementRepository {
  /// Create a new announcement
  Future<void> createAnnouncement({
    required String title,
    required String message,
    DateTime? expiresAt,
    required String createdBy,
    required String createdByEmail,
  });

  /// Update an existing announcement
  Future<void> updateAnnouncement({
    required String id,
    required String title,
    required String message,
    DateTime? expiresAt,
  });

  /// Delete an announcement
  Future<void> deleteAnnouncement(String id);

  /// Get all announcements
  Future<List<Announcement>> getAllAnnouncements();

  /// Get active announcements (not expired)
  Future<List<Announcement>> getActiveAnnouncements();

  /// Stream all announcements for real-time updates
  Stream<List<Announcement>> streamAllAnnouncements();

  /// Stream active announcements for real-time updates
  Stream<List<Announcement>> streamActiveAnnouncements();

  /// Get announcement by ID
  Future<Announcement?> getAnnouncementById(String id);

  /// Check for new announcements and show notifications
  Future<void> checkNewAnnouncements();

  /// Mark announcement as seen
  Future<void> markAnnouncementAsSeen(String id);

  /// Get seen announcements
  Future<Set<String>> getSeenAnnouncements();

  /// Clear all seen announcements
  Future<void> clearSeenAnnouncements();

  /// Search announcements by title or message
  Future<List<Announcement>> searchAnnouncements(String query);

  /// Get announcements count
  Future<int> getAnnouncementsCount();

  /// Get active announcements count
  Future<int> getActiveAnnouncementsCount();
}