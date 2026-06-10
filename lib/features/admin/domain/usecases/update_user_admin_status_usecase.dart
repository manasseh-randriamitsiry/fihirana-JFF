import 'package:fihirana/features/admin/domain/entities/admin_action_result.dart';
import 'package:fihirana/features/admin/domain/repositories/admin_repository.dart';

/// Update user admin status use case
class UpdateUserAdminStatusUseCase {
  final AdminRepository _repository;

  UpdateUserAdminStatusUseCase(this._repository);

  /// Execute the use case
  Future<AdminActionResult> execute(String userId, bool isAdmin) async {
    return await _repository.updateUserAdminStatus(userId, isAdmin);
  }
}
