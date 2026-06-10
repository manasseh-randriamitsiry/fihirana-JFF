import 'package:fihirana/features/admin/domain/repositories/admin_repository.dart';

/// Get user deletion statistics use case
class GetUserDeletionStatsUseCase {
  final AdminRepository _repository;

  GetUserDeletionStatsUseCase(this._repository);

  /// Execute the use case
  Future<Map<String, int>> execute(String userId) async {
    return await _repository.getUserDeletionStats(userId);
  }
}
