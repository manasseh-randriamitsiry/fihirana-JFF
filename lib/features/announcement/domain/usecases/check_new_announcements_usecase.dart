import 'package:fihirana/features/announcement/domain/repositories/announcement_repository.dart';

/// Check new announcements use case
class CheckNewAnnouncementsUseCase {
  final AnnouncementRepository _repository;

  CheckNewAnnouncementsUseCase(this._repository);

  /// Execute use case
  Future<void> execute() async {
    await _repository.checkNewAnnouncements();
  }
}
