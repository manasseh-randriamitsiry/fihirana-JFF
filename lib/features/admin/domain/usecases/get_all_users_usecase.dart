import 'package:fihirana/features/admin/domain/entities/admin_user.dart';
import 'package:fihirana/features/admin/domain/repositories/admin_repository.dart';

/// Get all users use case
class GetAllUsersUseCase {
  final AdminRepository _repository;

  GetAllUsersUseCase(this._repository);

  /// Execute use case
  Future<List<AdminUser>> execute() async {
    return await _repository.getAllUsers();
  }
}
