import 'package:fihirana/features/audio/domain/repositories/audio_repository.dart';

class PauseAudioUseCase {
  final AudioRepository _repository;

  PauseAudioUseCase(this._repository);

  Future<void> call() {
    return _repository.pause();
  }
}
