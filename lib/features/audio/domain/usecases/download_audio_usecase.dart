import 'package:fihirana/features/audio/domain/repositories/audio_repository.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';

class DownloadAudioUseCase {
  final AudioRepository _repository;

  DownloadAudioUseCase(this._repository);

  Future<void> call(Hymn hymn, {Function(double)? onProgress}) {
    return _repository.downloadAudioForHymn(hymn, onProgress: onProgress);
  }
}