import 'package:fihirana/features/audio/domain/repositories/audio_repository.dart';

class CheckAudioExistsUseCase {
  final AudioRepository _repository;

  CheckAudioExistsUseCase(this._repository);

  Future<bool> call(String hymnId) {
    return _repository.checkAudioFileExists(hymnId);
  }
}
