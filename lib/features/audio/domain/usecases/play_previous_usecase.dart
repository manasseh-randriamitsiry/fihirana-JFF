import 'package:fihirana/features/audio/domain/repositories/audio_repository.dart';

class PlayPreviousUseCase {
  final AudioRepository _repository;

  PlayPreviousUseCase(this._repository);

  Future<void> call() {
    return _repository.playPrevious();
  }
}
