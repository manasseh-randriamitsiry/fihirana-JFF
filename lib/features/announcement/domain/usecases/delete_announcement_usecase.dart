import 'package:fihirana/features/announcement/domain/repositories/announcement_repository.dart';

/// Delete announcement use case
class DeleteAnnouncementUseCase {
  final AnnouncementRepository _repository;

  DeleteAnnouncementUseCase(this._repository);

  /// Execute use case
  Future<void> execute(String id) async {
    await _repository.deleteAnnouncement(id);
  }
}