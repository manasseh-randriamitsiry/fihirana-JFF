import 'package:get/get.dart';
import 'package:fihirana/features/favorites/data/repositories/favorites_repository_impl.dart';
import 'package:fihirana/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:fihirana/features/hymn/data/services/hymn_service.dart';
import 'package:fihirana/features/audio/data/services/audio_service.dart';
import 'package:fihirana/features/favorites/domain/usecases/get_favorite_hymns_stream_usecase.dart';
import 'package:fihirana/features/favorites/domain/usecases/toggle_favorite_usecase.dart';
import 'package:fihirana/features/favorites/domain/usecases/check_audio_availability_usecase.dart';
import 'package:fihirana/features/favorites/domain/usecases/is_hymn_playing_usecase.dart';
import 'package:fihirana/features/favorites/presentation/controllers/favorites_controller.dart';

/// Dependency injection for favorites feature
class FavoritesDI {
  static const String _favoritesRepositoryTag = 'favoritesRepository';
  static const String _favoritesControllerTag = 'favoritesController';

  /// Initialize favorites dependencies
  static void initialize() {
    // Services (assuming they are already registered globally)
    // If not, they should be registered here

    // Repository
    Get.lazyPut<FavoritesRepository>(
      () => FavoritesRepositoryImpl(
        Get.find<HymnService>(),
        AudioService.instance,
      ),
      tag: _favoritesRepositoryTag,
    );

    // Use cases
    Get.lazyPut<GetFavoriteHymnsStreamUseCase>(
      () => GetFavoriteHymnsStreamUseCase(
        Get.find<FavoritesRepository>(tag: _favoritesRepositoryTag),
      ),
    );

    Get.lazyPut<ToggleFavoriteUseCase>(
      () => ToggleFavoriteUseCase(
        Get.find<FavoritesRepository>(tag: _favoritesRepositoryTag),
      ),
    );

    Get.lazyPut<CheckAudioAvailabilityUseCase>(
      () => CheckAudioAvailabilityUseCase(
        Get.find<FavoritesRepository>(tag: _favoritesRepositoryTag),
      ),
    );

    Get.lazyPut<IsHymnPlayingUseCase>(
      () => IsHymnPlayingUseCase(
        Get.find<FavoritesRepository>(tag: _favoritesRepositoryTag),
      ),
    );

    // Controller
    Get.lazyPut<FavoritesController>(
      () => FavoritesController(
        getFavoriteHymnsStreamUseCase:
            Get.find<GetFavoriteHymnsStreamUseCase>(),
        toggleFavoriteUseCase: Get.find<ToggleFavoriteUseCase>(),
        checkAudioAvailabilityUseCase:
            Get.find<CheckAudioAvailabilityUseCase>(),
        isHymnPlayingUseCase: Get.find<IsHymnPlayingUseCase>(),
      ),
      tag: _favoritesControllerTag,
    );
  }

  /// Get favorites controller
  static FavoritesController get favoritesController {
    return Get.find<FavoritesController>(tag: _favoritesControllerTag);
  }

  /// Dispose favorites dependencies
  static void dispose() {
    Get.delete<FavoritesController>(tag: _favoritesControllerTag);
    Get.delete<IsHymnPlayingUseCase>();
    Get.delete<CheckAudioAvailabilityUseCase>();
    Get.delete<ToggleFavoriteUseCase>();
    Get.delete<GetFavoriteHymnsStreamUseCase>();
    Get.delete<FavoritesRepository>(tag: _favoritesRepositoryTag);
  }

  /// Reset favorites dependencies (for testing)
  static void reset() {
    dispose();
    initialize();
  }
}
