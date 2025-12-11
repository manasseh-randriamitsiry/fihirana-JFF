import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fihirana/features/history/data/repositories/history_repository_impl.dart';
import 'package:fihirana/features/history/domain/repositories/history_repository.dart';
import 'package:fihirana/core/utils/firebase_sync_service.dart';
import 'package:fihirana/features/history/domain/usecases/load_user_history_usecase.dart';
import 'package:fihirana/features/history/domain/usecases/add_to_history_usecase.dart';
import 'package:fihirana/features/history/domain/usecases/delete_selected_history_items_usecase.dart';
import 'package:fihirana/features/history/domain/usecases/clear_history_usecase.dart';
import 'package:fihirana/features/history/presentation/controllers/history_controller.dart';

/// Dependency injection for history feature
class HistoryDI {
  static const String _historyRepositoryTag = 'historyRepository';
  static const String _historyControllerTag = 'historyController';

  /// Initialize history dependencies
  static void initialize() {
    // Services
    Get.lazyPut<SharedPreferences>(
      () => throw UnimplementedError('SharedPreferences should be initialized globally'),
    );
    Get.lazyPut<FirebaseAuth>(
      () => FirebaseAuth.instance,
    );
    Get.lazyPut<FirebaseSyncService>(
      () => FirebaseSyncService(),
    );

    // Repository
    Get.lazyPut<HistoryRepository>(
      () => HistoryRepositoryImpl(
        Get.find<FirebaseSyncService>(),
        Get.find<SharedPreferences>(),
        Get.find<FirebaseAuth>(),
      ),
      tag: _historyRepositoryTag,
    );

    // Use cases
    Get.lazyPut<LoadUserHistoryUseCase>(
      () => LoadUserHistoryUseCase(
        Get.find<HistoryRepository>(tag: _historyRepositoryTag),
      ),
    );

    Get.lazyPut<AddToHistoryUseCase>(
      () => AddToHistoryUseCase(
        Get.find<HistoryRepository>(tag: _historyRepositoryTag),
      ),
    );

    Get.lazyPut<DeleteSelectedHistoryItemsUseCase>(
      () => DeleteSelectedHistoryItemsUseCase(
        Get.find<HistoryRepository>(tag: _historyRepositoryTag),
      ),
    );

    Get.lazyPut<ClearHistoryUseCase>(
      () => ClearHistoryUseCase(
        Get.find<HistoryRepository>(tag: _historyRepositoryTag),
      ),
    );

    // Controller
    Get.lazyPut<HistoryController>(
      () => HistoryController(
        loadUserHistoryUseCase: Get.find<LoadUserHistoryUseCase>(),
        addToHistoryUseCase: Get.find<AddToHistoryUseCase>(),
        deleteSelectedHistoryItemsUseCase: Get.find<DeleteSelectedHistoryItemsUseCase>(),
        clearHistoryUseCase: Get.find<ClearHistoryUseCase>(),
      ),
      tag: _historyControllerTag,
    );
  }

  /// Get history controller
  static HistoryController get historyController {
    return Get.find<HistoryController>(tag: _historyControllerTag);
  }

  /// Get history repository
  static HistoryRepository get historyRepository {
    return Get.find<HistoryRepository>(tag: _historyRepositoryTag);
  }

  /// Dispose history dependencies
  static void dispose() {
    Get.delete<HistoryController>(tag: _historyControllerTag);
    Get.delete<ClearHistoryUseCase>();
    Get.delete<DeleteSelectedHistoryItemsUseCase>();
    Get.delete<AddToHistoryUseCase>();
    Get.delete<LoadUserHistoryUseCase>();
    Get.delete<HistoryRepository>(tag: _historyRepositoryTag);
    Get.delete<FirebaseSyncService>();
    Get.delete<FirebaseAuth>();
    Get.delete<SharedPreferences>();
  }

  /// Reset history dependencies (for testing)
  static void reset() {
    dispose();
    initialize();
  }
}