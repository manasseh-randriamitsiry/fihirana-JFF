import 'package:fihirana/features/announcement/domain/entities/announcement.dart';
import 'package:fihirana/features/announcement/domain/repositories/announcement_repository.dart';

/// Stream active announcements use case
class StreamActiveAnnouncementsUseCase {
  final AnnouncementRepository _repository;

  StreamActiveAnnouncementsUseCase(this._repository);

  /// Execute use case
  Stream<List<Announcement>> execute() {
    return _repository.streamActiveAnnouncements();
  }
}
