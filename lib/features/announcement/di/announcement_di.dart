import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fihirana/features/announcement/domain/repositories/announcement_repository.dart';
import 'package:fihirana/features/announcement/data/repositories/announcement_repository_impl.dart';
import 'package:fihirana/features/announcement/domain/usecases/create_announcement_usecase.dart';
import 'package:fihirana/features/announcement/domain/usecases/update_announcement_usecase.dart';
import 'package:fihirana/features/announcement/domain/usecases/delete_announcement_usecase.dart';
import 'package:fihirana/features/announcement/domain/usecases/get_all_announcements_usecase.dart';
import 'package:fihirana/features/announcement/domain/usecases/get_active_announcements_usecase.dart';
import 'package:fihirana/features/announcement/domain/usecases/stream_all_announcements_usecase.dart';
import 'package:fihirana/features/announcement/domain/usecases/stream_active_announcements_usecase.dart';
import 'package:fihirana/features/announcement/domain/usecases/check_new_announcements_usecase.dart';
import 'package:fihirana/features/announcement/domain/usecases/clear_seen_announcements_usecase.dart';
import 'package:fihirana/features/announcement/presentation/controllers/announcement_controller.dart';

/// Announcement dependency injection configuration
class AnnouncementDI {
  /// Initialize announcement dependencies
  static void init() {
    // Repository
    Get.lazyPut<AnnouncementRepository>(
      () => AnnouncementRepositoryImpl(),
      fenix: true,
    );

    // Use cases
    Get.lazyPut<CreateAnnouncementUseCase>(
      () => CreateAnnouncementUseCase(Get.find<AnnouncementRepository>()),
      fenix: true,
    );

    Get.lazyPut<UpdateAnnouncementUseCase>(
      () => UpdateAnnouncementUseCase(Get.find<AnnouncementRepository>()),
      fenix: true,
    );

    Get.lazyPut<DeleteAnnouncementUseCase>(
      () => DeleteAnnouncementUseCase(Get.find<AnnouncementRepository>()),
      fenix: true,
    );

    Get.lazyPut<GetAllAnnouncementsUseCase>(
      () => GetAllAnnouncementsUseCase(Get.find<AnnouncementRepository>()),
      fenix: true,
    );

    Get.lazyPut<GetActiveAnnouncementsUseCase>(
      () => GetActiveAnnouncementsUseCase(Get.find<AnnouncementRepository>()),
      fenix: true,
    );

    Get.lazyPut<StreamAllAnnouncementsUseCase>(
      () => StreamAllAnnouncementsUseCase(Get.find<AnnouncementRepository>()),
      fenix: true,
    );

    Get.lazyPut<StreamActiveAnnouncementsUseCase>(
      () =>
          StreamActiveAnnouncementsUseCase(Get.find<AnnouncementRepository>()),
      fenix: true,
    );

    Get.lazyPut<CheckNewAnnouncementsUseCase>(
      () => CheckNewAnnouncementsUseCase(Get.find<AnnouncementRepository>()),
      fenix: true,
    );

    Get.lazyPut<ClearSeenAnnouncementsUseCase>(
      () => ClearSeenAnnouncementsUseCase(Get.find<AnnouncementRepository>()),
      fenix: true,
    );

    // Controller
    Get.lazyPut<AnnouncementController>(
      () => AnnouncementController(
        createAnnouncementUseCase: Get.find<CreateAnnouncementUseCase>(),
        updateAnnouncementUseCase: Get.find<UpdateAnnouncementUseCase>(),
        deleteAnnouncementUseCase: Get.find<DeleteAnnouncementUseCase>(),
        getAllAnnouncementsUseCase: Get.find<GetAllAnnouncementsUseCase>(),
        getActiveAnnouncementsUseCase:
            Get.find<GetActiveAnnouncementsUseCase>(),
        streamAllAnnouncementsUseCase:
            Get.find<StreamAllAnnouncementsUseCase>(),
        streamActiveAnnouncementsUseCase:
            Get.find<StreamActiveAnnouncementsUseCase>(),
        checkNewAnnouncementsUseCase: Get.find<CheckNewAnnouncementsUseCase>(),
        clearSeenAnnouncementsUseCase:
            Get.find<ClearSeenAnnouncementsUseCase>(),
        auth: Get.find<FirebaseAuth>(),
      ),
      fenix: true,
    );
  }
}
