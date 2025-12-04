import 'package:fihirana/features/audio/domain/repositories/audio_repository.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';

class SetPlaylistUseCase {
  final AudioRepository _repository;

  SetPlaylistUseCase(this._repository);

  Future<void> call(List<Hymn> playlist, int initialIndex) {
    return _repository.setPlaylist(playlist, initialIndex);
  }
}