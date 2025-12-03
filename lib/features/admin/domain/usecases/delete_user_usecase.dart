import 'package:fihirana/features/admin/domain/entities/admin_action_result.dart';
import 'package:fihirana/features/admin/domain/repositories/admin_repository.dart';

/// Delete user use case
class DeleteUserUseCase {
  final AdminRepository _repository;

  DeleteUserUseCase(this._repository);

  /// Execute the use case
  Future<AdminActionResult> execute(String userId) async {
    return await _repository.deleteUser(userId);
  }
}