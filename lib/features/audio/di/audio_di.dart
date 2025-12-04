import 'package:get/get.dart';
import 'package:fihirana/features/audio/domain/repositories/audio_repository.dart';
import 'package:fihirana/features/audio/data/repositories/audio_repository_impl.dart';
import 'package:fihirana/features/audio/data/services/audio_service.dart';
import 'package:fihirana/features/audio/domain/usecases/play_hymn_usecase.dart';
import 'package:fihirana/features/audio/domain/usecases/pause_audio_usecase.dart';
import 'package:fihirana/features/audio/domain/usecases/resume_audio_usecase.dart';
import 'package:fihirana/features/audio/domain/usecases/stop_audio_usecase.dart';
import 'package:fihirana/features/audio/domain/usecases/set_playlist_usecase.dart';
import 'package:fihirana/features/audio/domain/usecases/play_next_usecase.dart';
import 'package:fihirana/features/audio/domain/usecases/play_previous_usecase.dart';
import 'package:fihirana/features/audio/domain/usecases/check_audio_exists_usecase.dart';
import 'package:fihirana/features/audio/domain/usecases/download_audio_usecase.dart';
import 'package:fihirana/features/audio/presentation/controllers/audio_controller.dart';

/// Audio dependency injection configuration
class AudioDI {
  /// Initialize audio dependencies
  static void init() {
    // Service
    Get.lazyPut<AudioService>(
      () => AudioService.instance,
    );

    // Repository
    Get.lazyPut<AudioRepository>(
      () => AudioRepositoryImpl(Get.find<AudioService>()),
    );

    // Use cases
    Get.lazyPut<PlayHymnUseCase>(
      () => PlayHymnUseCase(Get.find<AudioRepository>()),
    );

    Get.lazyPut<PauseAudioUseCase>(
      () => PauseAudioUseCase(Get.find<AudioRepository>()),
    );

    Get.lazyPut<ResumeAudioUseCase>(
      () => ResumeAudioUseCase(Get.find<AudioRepository>()),
    );

    Get.lazyPut<StopAudioUseCase>(
      () => StopAudioUseCase(Get.find<AudioRepository>()),
    );

    Get.lazyPut<SetPlaylistUseCase>(
      () => SetPlaylistUseCase(Get.find<AudioRepository>()),
    );

    Get.lazyPut<PlayNextUseCase>(
      () => PlayNextUseCase(Get.find<AudioRepository>()),
    );

    Get.lazyPut<PlayPreviousUseCase>(
      () => PlayPreviousUseCase(Get.find<AudioRepository>()),
    );

    Get.lazyPut<CheckAudioExistsUseCase>(
      () => CheckAudioExistsUseCase(Get.find<AudioRepository>()),
    );

    Get.lazyPut<DownloadAudioUseCase>(
      () => DownloadAudioUseCase(Get.find<AudioRepository>()),
    );

    // Controller
    Get.lazyPut<AudioController>(
      () => AudioController(
        playHymnUseCase: Get.find<PlayHymnUseCase>(),
        pauseAudioUseCase: Get.find<PauseAudioUseCase>(),
        resumeAudioUseCase: Get.find<ResumeAudioUseCase>(),
        stopAudioUseCase: Get.find<StopAudioUseCase>(),
        setPlaylistUseCase: Get.find<SetPlaylistUseCase>(),
        playNextUseCase: Get.find<PlayNextUseCase>(),
        playPreviousUseCase: Get.find<PlayPreviousUseCase>(),
        checkAudioExistsUseCase: Get.find<CheckAudioExistsUseCase>(),
        downloadAudioUseCase: Get.find<DownloadAudioUseCase>(),
        repository: Get.find<AudioRepository>(),
      ),
    );
  }
}