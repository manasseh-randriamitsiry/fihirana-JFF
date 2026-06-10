import 'package:fihirana/features/announcement/domain/entities/announcement.dart';
import 'package:fihirana/features/announcement/domain/repositories/announcement_repository.dart';

/// Stream all announcements use case
class StreamAllAnnouncementsUseCase {
  final AnnouncementRepository _repository;

  StreamAllAnnouncementsUseCase(this._repository);

  /// Execute use case
  Stream<List<Announcement>> execute() {
    return _repository.streamAllAnnouncements();
  }
}
