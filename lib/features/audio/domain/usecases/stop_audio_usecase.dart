import 'package:fihirana/features/audio/domain/repositories/audio_repository.dart';

class StopAudioUseCase {
  final AudioRepository _repository;

  StopAudioUseCase(this._repository);

  Future<void> call() {
    return _repository.stop();
  }
}
