import 'package:get/get.dart';
import 'package:fihirana/features/bible/domain/repositories/bible_repository.dart';
import 'package:fihirana/features/bible/data/repositories/bible_repository_impl.dart';
import 'package:fihirana/features/bible/data/services/bible_service.dart';
import 'package:fihirana/features/bible/domain/usecases/initialize_bible_usecase.dart';
import 'package:fihirana/features/bible/domain/usecases/get_all_books_usecase.dart';
import 'package:fihirana/features/bible/domain/usecases/get_book_usecase.dart';
import 'package:fihirana/features/bible/domain/usecases/get_chapter_usecase.dart';
import 'package:fihirana/features/bible/domain/usecases/search_verses_usecase.dart';
import 'package:fihirana/features/bible/domain/usecases/search_books_usecase.dart';
import 'package:fihirana/features/bible/domain/usecases/get_random_verse_usecase.dart';
import 'package:fihirana/features/bible/data/services/bible_highlight_service.dart';
import 'package:fihirana/features/bible/presentation/controllers/bible_controller.dart';

/// Bible dependency injection configuration
class BibleDI {
  /// Initialize bible dependencies
  static void init() {
    // Services
    Get.lazyPut<BibleService>(
      () => BibleService(),
    );

    Get.lazyPut<BibleHighlightService>(
      () => BibleHighlightService(),
    );

    // Repository
    Get.lazyPut<IBibleService>(
      () => BibleRepositoryImpl(Get.find<BibleService>()),
    );

    // Use cases
    Get.lazyPut<InitializeBibleUseCase>(
      () => InitializeBibleUseCase(Get.find<IBibleService>()),
    );

    Get.lazyPut<GetAllBooksUseCase>(
      () => GetAllBooksUseCase(Get.find<IBibleService>()),
    );

    Get.lazyPut<GetBookUseCase>(
      () => GetBookUseCase(Get.find<IBibleService>()),
    );

    Get.lazyPut<GetChapterUseCase>(
      () => GetChapterUseCase(Get.find<IBibleService>()),
    );

    Get.lazyPut<SearchVersesUseCase>(
      () => SearchVersesUseCase(Get.find<IBibleService>()),
    );

    Get.lazyPut<SearchBooksUseCase>(
      () => SearchBooksUseCase(Get.find<IBibleService>()),
    );

    Get.lazyPut<GetRandomVerseUseCase>(
      () => GetRandomVerseUseCase(Get.find<IBibleService>()),
    );

    // Controller
    Get.lazyPut<BibleController>(
      () => BibleController(
        initializeBibleUseCase: Get.find<InitializeBibleUseCase>(),
        getAllBooksUseCase: Get.find<GetAllBooksUseCase>(),
        getBookUseCase: Get.find<GetBookUseCase>(),
        searchBooksUseCase: Get.find<SearchBooksUseCase>(),
        searchVersesUseCase: Get.find<SearchVersesUseCase>(),
        highlightService: Get.find<BibleHighlightService>(),
      ),
    );
  }
}
