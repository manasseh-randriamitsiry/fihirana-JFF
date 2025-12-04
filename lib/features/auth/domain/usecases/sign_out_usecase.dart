import 'package:fihirana/features/auth/domain/repositories/auth_repository.dart';

class SignOutUseCase {
  final AuthRepository _repository;

  SignOutUseCase(this._repository);

  Future<void> call() {
    return _repository.signOut();
  }
}