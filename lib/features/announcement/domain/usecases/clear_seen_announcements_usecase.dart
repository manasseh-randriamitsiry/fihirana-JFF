import 'package:fihirana/features/announcement/domain/repositories/announcement_repository.dart';

/// Clear seen announcements use case
class ClearSeenAnnouncementsUseCase {
  final AnnouncementRepository _repository;

  ClearSeenAnnouncementsUseCase(this._repository);

  /// Execute use case
  Future<void> execute() async {
    await _repository.clearSeenAnnouncements();
  }
}
