import 'package:fihirana/features/admin/domain/entities/admin_stats.dart';
import 'package:fihirana/features/admin/domain/repositories/admin_repository.dart';

/// Stream admin statistics use case
class StreamAdminStatsUseCase {
  final AdminRepository _repository;

  StreamAdminStatsUseCase(this._repository);

  /// Execute the use case
  Stream<AdminStats> execute() {
    return _repository.getAdminStatsStream();
  }
}
