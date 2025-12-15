import 'package:get/get.dart';
import 'package:fihirana/features/daily_verse/data/repositories/daily_verse_repository_impl.dart';
import 'package:fihirana/features/daily_verse/domain/repositories/daily_verse_repository.dart';
import 'package:fihirana/features/daily_verse/data/services/daily_verse_service.dart';
import 'package:fihirana/features/daily_verse/domain/usecases/get_verse_of_the_day_usecase.dart';
import 'package:fihirana/features/daily_verse/domain/usecases/load_daily_verse_settings_usecase.dart';
import 'package:fihirana/features/daily_verse/domain/usecases/save_daily_verse_settings_usecase.dart';
import 'package:fihirana/features/daily_verse/domain/usecases/toggle_daily_verse_usecase.dart';
import 'package:fihirana/features/daily_verse/domain/usecases/update_notification_time_usecase.dart';
import 'package:fihirana/features/daily_verse/domain/usecases/send_test_notification_usecase.dart';
import 'package:fihirana/features/daily_verse/presentation/controllers/daily_verse_controller.dart';

/// Dependency injection for daily verse feature
class DailyVerseDI {
  static const String _dailyVerseRepositoryTag = 'dailyVerseRepository';
  static const String _dailyVerseControllerTag = 'dailyVerseController';

  /// Initialize daily verse dependencies
  static void initialize() {
    // Service
    Get.lazyPut<DailyVerseService>(
      () => DailyVerseService(),
    );

    // Repository
    Get.lazyPut<DailyVerseRepository>(
      () => DailyVerseRepositoryImpl(
        Get.find<DailyVerseService>(),
      ),
      tag: _dailyVerseRepositoryTag,
    );

    // Use cases
    Get.lazyPut<GetVerseOfTheDayUseCase>(
      () => GetVerseOfTheDayUseCase(
        Get.find<DailyVerseRepository>(tag: _dailyVerseRepositoryTag),
      ),
    );

    Get.lazyPut<LoadDailyVerseSettingsUseCase>(
      () => LoadDailyVerseSettingsUseCase(
        Get.find<DailyVerseRepository>(tag: _dailyVerseRepositoryTag),
      ),
    );

    Get.lazyPut<SaveDailyVerseSettingsUseCase>(
      () => SaveDailyVerseSettingsUseCase(
        Get.find<DailyVerseRepository>(tag: _dailyVerseRepositoryTag),
      ),
    );

    Get.lazyPut<ToggleDailyVerseUseCase>(
      () => ToggleDailyVerseUseCase(
        Get.find<DailyVerseRepository>(tag: _dailyVerseRepositoryTag),
      ),
    );

    Get.lazyPut<UpdateNotificationTimeUseCase>(
      () => UpdateNotificationTimeUseCase(
        Get.find<DailyVerseRepository>(tag: _dailyVerseRepositoryTag),
      ),
    );

    Get.lazyPut<SendTestNotificationUseCase>(
      () => SendTestNotificationUseCase(
        Get.find<DailyVerseRepository>(tag: _dailyVerseRepositoryTag),
      ),
    );

    // Controller
    Get.lazyPut<DailyVerseController>(
      () => DailyVerseController(
        getVerseOfTheDayUseCase: Get.find<GetVerseOfTheDayUseCase>(),
        loadSettingsUseCase: Get.find<LoadDailyVerseSettingsUseCase>(),
        saveSettingsUseCase: Get.find<SaveDailyVerseSettingsUseCase>(),
        toggleDailyVerseUseCase: Get.find<ToggleDailyVerseUseCase>(),
        updateNotificationTimeUseCase: Get.find<UpdateNotificationTimeUseCase>(),
        sendTestNotificationUseCase: Get.find<SendTestNotificationUseCase>(),
      ),
      tag: _dailyVerseControllerTag,
    );
  }

  /// Get daily verse controller
  static DailyVerseController get dailyVerseController {
    if (!Get.isRegistered<DailyVerseController>(tag: _dailyVerseControllerTag)) {
      initialize();
    }

    return Get.find<DailyVerseController>(tag: _dailyVerseControllerTag);
  }

  /// Get daily verse repository
  static DailyVerseRepository get dailyVerseRepository {
    return Get.find<DailyVerseRepository>(tag: _dailyVerseRepositoryTag);
  }

  /// Dispose daily verse dependencies
  static void dispose() {
    Get.delete<DailyVerseController>(tag: _dailyVerseControllerTag);
    Get.delete<SendTestNotificationUseCase>();
    Get.delete<UpdateNotificationTimeUseCase>();
    Get.delete<ToggleDailyVerseUseCase>();
    Get.delete<SaveDailyVerseSettingsUseCase>();
    Get.delete<LoadDailyVerseSettingsUseCase>();
    Get.delete<GetVerseOfTheDayUseCase>();
    Get.delete<DailyVerseRepository>(tag: _dailyVerseRepositoryTag);
    Get.delete<DailyVerseService>();
  }

  /// Reset daily verse dependencies (for testing)
  static void reset() {
    dispose();
    initialize();
  }
}