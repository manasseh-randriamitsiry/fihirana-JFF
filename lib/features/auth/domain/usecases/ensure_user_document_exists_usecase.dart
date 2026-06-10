import 'package:fihirana/features/auth/domain/repositories/auth_repository.dart';

class EnsureUserDocumentExistsUseCase {
  final AuthRepository _repository;

  EnsureUserDocumentExistsUseCase(this._repository);

  Future<void> call() {
    return _repository.ensureUserDocumentExists();
  }
}
