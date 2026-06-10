import 'package:fihirana/features/admin/domain/entities/admin_action_result.dart';
import 'package:fihirana/features/admin/domain/repositories/admin_repository.dart';

/// Block user use case
class BlockUserUseCase {
  final AdminRepository _repository;

  BlockUserUseCase(this._repository);

  /// Execute the use case
  Future<AdminActionResult> execute(String userId, bool isBlocked) async {
    return await _repository.blockUser(userId, isBlocked);
  }
}
