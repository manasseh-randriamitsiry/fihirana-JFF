import 'package:get/get.dart';
import 'package:fihirana/features/hymn/domain/repositories/hymn_repository.dart';
import 'package:fihirana/features/hymn/data/repositories/hymn_repository_impl.dart';
import 'package:fihirana/features/hymn/data/services/hymn_service.dart';
import 'package:fihirana/features/hymn/domain/usecases/get_all_hymns_usecase.dart';
import 'package:fihirana/features/hymn/domain/usecases/get_hymn_by_id_usecase.dart';
import 'package:fihirana/features/hymn/domain/usecases/search_hymns_usecase.dart';
import 'package:fihirana/features/hymn/domain/usecases/get_favorite_hymns_usecase.dart';
import 'package:fihirana/features/hymn/domain/usecases/add_to_favorites_usecase.dart';
import 'package:fihirana/features/hymn/domain/usecases/remove_from_favorites_usecase.dart';
import 'package:fihirana/features/hymn/domain/usecases/get_random_hymn_usecase.dart';
import 'package:fihirana/features/hymn/domain/usecases/is_favorite_usecase.dart';
import 'package:fihirana/features/hymn/presentation/controllers/hymn_controller.dart';

/// Hymn dependency injection configuration
class HymnDI {
  /// Initialize hymn dependencies
  static void init() {
    // Service
    Get.lazyPut<HymnService>(
      () => HymnService(),
    );

    // Repository
    Get.lazyPut<IHymnService>(
      () => HymnRepositoryImpl(Get.find<HymnService>()),
    );

    // Use cases
    Get.lazyPut<GetAllHymnsUseCase>(
      () => GetAllHymnsUseCase(Get.find<IHymnService>()),
    );

    Get.lazyPut<GetHymnByIdUseCase>(
      () => GetHymnByIdUseCase(Get.find<IHymnService>()),
    );

    Get.lazyPut<SearchHymnsUseCase>(
      () => SearchHymnsUseCase(Get.find<IHymnService>()),
    );

    Get.lazyPut<GetFavoriteHymnsUseCase>(
      () => GetFavoriteHymnsUseCase(Get.find<IHymnService>()),
    );

    Get.lazyPut<AddToFavoritesUseCase>(
      () => AddToFavoritesUseCase(Get.find<IHymnService>()),
    );

    Get.lazyPut<RemoveFromFavoritesUseCase>(
      () => RemoveFromFavoritesUseCase(Get.find<IHymnService>()),
    );

    Get.lazyPut<GetRandomHymnUseCase>(
      () => GetRandomHymnUseCase(Get.find<IHymnService>()),
    );

    Get.lazyPut<IsFavoriteUseCase>(
      () => IsFavoriteUseCase(Get.find<IHymnService>()),
    );

    // Controller
    Get.lazyPut<HymnController>(
      () => HymnController(
        searchHymnsUseCase: Get.find<SearchHymnsUseCase>(),
        addToFavoritesUseCase: Get.find<AddToFavoritesUseCase>(),
        removeFromFavoritesUseCase: Get.find<RemoveFromFavoritesUseCase>(),
        isFavoriteUseCase: Get.find<IsFavoriteUseCase>(),
      ),
    );
  }
}