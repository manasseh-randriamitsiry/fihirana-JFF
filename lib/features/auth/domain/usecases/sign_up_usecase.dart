import 'package:fihirana/features/auth/domain/entities/user.dart';
import 'package:fihirana/features/auth/domain/repositories/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository _repository;

  SignUpUseCase(this._repository);

  Future<User?> call(String email, String password) async {
    return await _repository.signUpWithEmailAndPassword(email, password);
  }
}