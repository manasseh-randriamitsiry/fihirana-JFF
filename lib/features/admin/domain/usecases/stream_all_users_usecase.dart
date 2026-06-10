import 'package:fihirana/features/admin/domain/entities/admin_user.dart';
import 'package:fihirana/features/admin/domain/repositories/admin_repository.dart';

/// Stream all users use case
class StreamAllUsersUseCase {
  final AdminRepository _repository;

  StreamAllUsersUseCase(this._repository);

  /// Execute the use case
  Stream<List<AdminUser>> execute() {
    return _repository.getAllUsersStream();
  }
}
