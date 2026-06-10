import 'package:fihirana/features/bible/domain/repositories/bible_repository.dart';

class InitializeBibleUseCase {
  final IBibleService _repository;

  InitializeBibleUseCase(this._repository);

  Future<void> call([Function(String)? loadingCallback]) {
    return _repository.initialize(loadingCallback);
  }
}
