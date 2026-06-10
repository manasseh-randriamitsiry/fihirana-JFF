import 'package:fihirana/features/audio/domain/repositories/audio_repository.dart';

class PlayNextUseCase {
  final AudioRepository _repository;

  PlayNextUseCase(this._repository);

  Future<void> call() {
    return _repository.playNext();
  }
}
