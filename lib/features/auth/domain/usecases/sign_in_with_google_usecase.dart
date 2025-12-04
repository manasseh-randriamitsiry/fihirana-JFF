import 'package:fihirana/features/auth/domain/entities/user.dart';
import 'package:fihirana/features/auth/domain/repositories/auth_repository.dart';

class SignInWithGoogleUseCase {
  final AuthRepository _repository;

  SignInWithGoogleUseCase(this._repository);

  Future<User?> call() async {
    return await _repository.signInWithGoogle();
  }
}