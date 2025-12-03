import 'package:fihirana/features/announcement/domain/entities/announcement.dart';
import 'package:fihirana/features/announcement/domain/repositories/announcement_repository.dart';

/// Get active announcements use case
class GetActiveAnnouncementsUseCase {
  final AnnouncementRepository _repository;

  GetActiveAnnouncementsUseCase(this._repository);

  /// Execute use case
  Future<List<Announcement>> execute() async {
    return await _repository.getActiveAnnouncements();
  }
}