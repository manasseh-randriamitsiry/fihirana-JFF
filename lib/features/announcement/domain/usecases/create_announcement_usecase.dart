import 'package:fihirana/features/announcement/domain/repositories/announcement_repository.dart';

/// Create announcement use case
class CreateAnnouncementUseCase {
  final AnnouncementRepository _repository;

  CreateAnnouncementUseCase(this._repository);

  /// Execute use case
  Future<void> execute({
    required String title,
    required String message,
    DateTime? expiresAt,
    required String createdBy,
    required String createdByEmail,
  }) async {
    await _repository.createAnnouncement(
      title: title,
      message: message,
      expiresAt: expiresAt,
      createdBy: createdBy,
      createdByEmail: createdByEmail,
    );
  }
}
