import 'package:fihirana/features/audio/domain/repositories/audio_repository.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';

class PlayHymnUseCase {
  final AudioRepository _repository;

  PlayHymnUseCase(this._repository);

  Future<void> call(Hymn hymn, {String? customAudioUrl}) {
    return _repository.playHymn(hymn, customAudioUrl: customAudioUrl);
  }
}
