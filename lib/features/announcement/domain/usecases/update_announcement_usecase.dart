import 'package:fihirana/features/announcement/domain/repositories/announcement_repository.dart';

/// Update announcement use case
class UpdateAnnouncementUseCase {
  final AnnouncementRepository _repository;

  UpdateAnnouncementUseCase(this._repository);

  /// Execute use case
  Future<void> execute({
    required String id,
    required String title,
    required String message,
    DateTime? expiresAt,
  }) async {
    await _repository.updateAnnouncement(
      id: id,
      title: title,
      message: message,
      expiresAt: expiresAt,
    );
  }
}
