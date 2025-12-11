import 'package:fihirana/features/audio/domain/repositories/audio_repository.dart';

class ResumeAudioUseCase {
  final AudioRepository _repository;

  ResumeAudioUseCase(this._repository);

  Future<void> call() {
    return _repository.resume();
  }
}