import 'package:fihirana/features/announcement/domain/entities/announcement.dart';
import 'package:fihirana/features/announcement/domain/repositories/announcement_repository.dart';

/// Get all announcements use case
class GetAllAnnouncementsUseCase {
  final AnnouncementRepository _repository;

  GetAllAnnouncementsUseCase(this._repository);

  /// Execute use case
  Future<List<Announcement>> execute() async {
    return await _repository.getAllAnnouncements();
  }
}