import 'package:fihirana/features/auth/domain/entities/user.dart';
import 'package:fihirana/features/auth/domain/repositories/auth_repository.dart';

class SignInUseCase {
  final AuthRepository _repository;

  SignInUseCase(this._repository);

  Future<User?> call(String email, String password) async {
    return await _repository.signInWithEmailAndPassword(email, password);
  }
}
