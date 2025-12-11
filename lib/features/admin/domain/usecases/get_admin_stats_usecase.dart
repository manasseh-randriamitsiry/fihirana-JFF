import 'package:fihirana/features/admin/domain/entities/admin_stats.dart';
import 'package:fihirana/features/admin/domain/repositories/admin_repository.dart';

/// Get admin statistics use case
class GetAdminStatsUseCase {
  final AdminRepository _repository;

  GetAdminStatsUseCase(this._repository);

  /// Execute the use case
  Future<AdminStats> execute() async {
    return await _repository.getAdminStats();
  }
}